import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:sl_editor/client/assets/asset_thumbs.dart';
import 'package:sl_editor/client/client.dart';
import 'package:sl_editor/importers/unsupported.dart';
import 'package:sl_shared/sl_shared.dart';
import 'package:uuid/uuid.dart';

abstract interface class UploadFile {
  String get path;
  String get name;
  String get extension;

  int get size;

  FutureOr<Uint8List> readAsBytes();
  Stream<Uint8List> openRead(int offset, int chunkSize);
}

class AssetImportContext {
  final UUID? directory;
  final List<UploadFile> files;
  final Map<String, UploadFile> pathToFile;

  AssetImportContext({
    required this.directory,
    required this.files,
    required this.pathToFile,
  });
}

class AssetThumbCreateInfo {
  final Uint8List bytes;
  final String mime;

  AssetThumbCreateInfo({
    required this.bytes,
    required this.mime,
  });
}

class AssetCreateInfo {
  final UUID uuid;
  final UUID? parent;
  final String name;
  final AssetType type;
  final dynamic properties;
  final UploadFile? uploadFile;
  final AssetThumbCreateInfo? uploadThumb;

  AssetCreateInfo({
    required this.uuid,
    required this.parent,
    required this.name,
    required this.type,
    this.properties,
    this.uploadFile,
    this.uploadThumb,
  });
}

class AssetImportResult {
  final Set<UploadFile> consumed;
  final List<AssetCreateInfo> createInfos;

  AssetImportResult({
    required this.consumed,
    required this.createInfos,
  });

  factory AssetImportResult.empty() => AssetImportResult(consumed: {}, createInfos: []);

  void add(AssetImportResult other) {
    consumed.addAll(other.consumed);
    createInfos.addAll(other.createInfos);
  }
}

class AssetImporter {
  final List<String> extensions;
  final int priority;
  final FutureOr<AssetImportResult> Function(UploadFile file, AssetImportContext ctx) import;
  final FutureOr<AssetType> Function(UploadFile file, AssetImportContext ctx)? inferAssetType;

  AssetImporter({
    required this.extensions,
    required this.priority,
    required this.import,
    required this.inferAssetType,
  });
}

class Assets {
  static final _extensionToImporter = <String, AssetImporter>{};

  static void registerImporter(AssetImporter importer) {
    for (final extension in importer.extensions) {
      _extensionToImporter[extension] = importer;
    }
  }

  static int _getImportPriority(String name) {
    return _extensionToImporter[p.extension(name).toLowerCase()]?.priority ?? 0;
  }

  static Future<void> createScene(UUID? directory) async {
    final uuid = Uuid().v4();
    final parent = directory;
    final name = 'New Scene';
    final type = AssetType.nodeTree.name;
    final updatedAt = DateTime.now().toIso8601String();

    final database = Client.get().assetSystem.sharedDatabase;
    await database.execute(
      'INSERT INTO assets (uuid, parent, name, type, updated_at) VALUES (?, ?, ?, ?, ?)',
      [uuid, parent, name, type, updatedAt],
    );
  }

  static Future<void> import(UUID? directory, List<UploadFile> files) async {
    files.sort((a, b) => _getImportPriority(b.path).compareTo(_getImportPriority(a.path)));
    final pathToFile = Map.fromEntries(files.map((file) => MapEntry(p.normalize(file.path), file)));

    final ctx = AssetImportContext(
      directory: directory,
      files: files,
      pathToFile: pathToFile,
    );

    final timestamp = DateTime.now().toIso8601String();

    final consumed = <UploadFile>{};
    final arguments = <List>[];
    final toUpload = <UUID, UploadFile>{};
    final toUploadThumbs = <UUID, AssetThumbCreateInfo>{};

    for (final file in files) {
      if (consumed.contains(file)) continue;

      final extension = p.extension(file.path).toLowerCase();
      final importer = _extensionToImporter[extension];
      final importFunc = importer?.import ?? UnsupportedImporter.import;

      final result = await importFunc(file, ctx);

      consumed.addAll(result.consumed);
      for (final createInfo in result.createInfos) {
        arguments.add([
          createInfo.uuid,
          createInfo.parent,
          createInfo.name,
          createInfo.type.name,
          createInfo.properties == null ? null : jsonEncode(createInfo.properties),
          timestamp,
          createInfo.uploadThumb?.mime,
        ]);

        if (createInfo.uploadFile != null) {
          toUpload[createInfo.uuid] = createInfo.uploadFile!;
        }
        if (createInfo.uploadThumb != null) {
          toUploadThumbs[createInfo.uuid] = createInfo.uploadThumb!;
        }
      }
    }

    for (final entry in toUploadThumbs.entries) {
      final uuid = entry.key;
      final thumbCreateInfo = entry.value;
      await AssetThumbs.upload(uuid, thumbCreateInfo.bytes);
    }

    final database = Client.get().assetSystem.sharedDatabase;
    final batch = database.batch();
    for (final argumentList in arguments) {
      await batch.execute(
        'INSERT INTO assets (uuid, parent, name, type, properties, updated_at, thumb_mime) VALUES (?, ?, ?, ?, ?, ?, ?)',
        argumentList,
      );
    }
    await batch.commit();

    for (final entry in toUpload.entries) {
      final uuid = entry.key;
      final file = entry.value;
      await Client.get().assetSystem.upload(uuid, file);
    }
  }

  static FutureOr<AssetType> inferAssetType(UploadFile file, AssetImportContext ctx) async {
    final importer = _extensionToImporter[p.extension(file.path).toLowerCase()];
    return (await importer?.inferAssetType?.call(file, ctx)) ?? .unsupported;
  }

  static void tryDeleteAssets(Set<UUID> uuids) {
    Client.get().send(
      CtsDeleteAssets(
        uuids: uuids,
      ),
    );
  }
}
