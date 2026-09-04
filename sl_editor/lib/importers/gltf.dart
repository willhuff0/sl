import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:sl_editor/assets.dart';
import 'package:sl_editor/client/client.dart';
import 'package:sl_engine/editor/sl_editor.dart';
import 'package:sl_engine/gl/gltf.dart';
import 'package:sl_engine/utils/resource_loader.dart';
import 'package:sl_shared/sl_shared.dart';
import 'package:uuid/uuid.dart';

class GLTFAssetResourceLoader implements ResourceLoader {
  final Map<String, UUID> redirects;

  GLTFAssetResourceLoader({
    required this.redirects,
  });

  @override
  Future<Uint8List?> loadBytes(String path) async {
    final normalizedPath = p.normalize(path);
    final uuid = redirects[normalizedPath]!;
    final bytes = await Client.get().assetSystem.getAssetBlob(uuid);
    return bytes!;
  }

  @override
  Future<String?> loadString(String path) async {
    final bytes = await loadBytes(path);
    if (bytes == null) return null;
    return utf8.decode(bytes);
  }
}

class _GLTFImporterResourceLoader implements ResourceLoader {
  final String gltfRootDirectory;
  final AssetImportContext ctx;

  _GLTFImporterResourceLoader({
    required this.gltfRootDirectory,
    required this.ctx,
  });

  final _loadedPaths = <String>{};

  UnmodifiableSetView<String> getLoadedPaths() {
    return UnmodifiableSetView(_loadedPaths);
  }

  @override
  Future<Uint8List?> loadBytes(String path) async {
    final normalizedPath = p.normalize(path);
    final assetPath = p.normalize(p.join(gltfRootDirectory, normalizedPath));
    final bytes = await ctx.pathToFile[assetPath]?.readAsBytes();
    if (bytes != null) _loadedPaths.add(normalizedPath);
    return bytes;
  }

  @override
  Future<String?> loadString(String path) async {
    final bytes = await loadBytes(path);
    if (bytes == null) return null;
    return utf8.decode(bytes);
  }
}

class GLTFImporter {
  static final registration = AssetImporter(
    extensions: [
      '.gltf',
      '.glb',
    ],
    priority: 1,
    import: import,
    inferAssetType: (_, _) => .model,
  );

  static Future<AssetImportResult> import(UploadFile file, AssetImportContext ctx) async {
    final gltfRootDirectory = p.dirname(p.normalize(file.path));
    final gltfName = p.basename(file.path);
    final extension = file.extension;
    final resourceLoader = _GLTFImporterResourceLoader(
      gltfRootDirectory: gltfRootDirectory,
      ctx: ctx,
    );

    final gltf = await GLTF.load(gltfName, resourceLoader: resourceLoader);
    if (gltf == null) return AssetImportResult.empty();

    while (SLEditor.modelPreviewGenerator == null) {
      await Future.delayed(Duration(milliseconds: 100));
    }
    final (thumbBytes, thumbMime) = await SLEditor.modelPreviewGenerator!.generateModelPreview(gltf.root, size: 256);

    final gltfUuid = Uuid().v4();
    final createInfos = <AssetCreateInfo>[];

    final consumed = <UploadFile>{};
    final redirects = <String, UUID>{};
    for (final loadedPath in resourceLoader.getLoadedPaths()) {
      if (loadedPath == gltfName) continue;

      final assetPath = p.normalize(p.join(gltfRootDirectory, loadedPath));
      final subFile = ctx.pathToFile[assetPath]!;
      consumed.add(subFile);

      final uuid = Uuid().v4();
      redirects[loadedPath] = uuid;

      createInfos.add(
        AssetCreateInfo(
          uuid: uuid,
          parent: gltfUuid,
          name: subFile.name,
          type: await Assets.inferAssetType(file, ctx),
          uploadFile: subFile,
        ),
      );
    }

    createInfos.add(
      AssetCreateInfo(
        uuid: gltfUuid,
        parent: ctx.directory,
        name: file.name,
        type: .model,
        properties: {
          'extension': extension,
          if (redirects.isNotEmpty) 'redirects': redirects,
        },
        uploadFile: file,
        uploadThumb: AssetThumbCreateInfo(
          bytes: thumbBytes,
          mime: thumbMime,
        ),
      ),
    );

    return AssetImportResult(
      consumed: consumed,
      createInfos: createInfos,
    );
  }
}
