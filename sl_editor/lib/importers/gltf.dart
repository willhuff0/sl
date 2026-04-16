import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:path/path.dart' as p;
import 'package:sl_editor/assets.dart';
import 'package:sl_engine/editor/sl_editor.dart';
import 'package:sl_engine/gl/gltf_loader.dart';
import 'package:sl_engine/utils/resource_loader.dart';
import 'package:sl_shared/sl_shared.dart';
import 'package:uuid/uuid.dart';

class _GLTFImporterResourceLoader implements ResourceLoader {
  final AssetImportContext ctx;

  _GLTFImporterResourceLoader({required this.ctx});

  final _loadedPaths = <String>{};

  UnmodifiableSetView<String> getLoadedPaths() {
    return UnmodifiableSetView(_loadedPaths);
  }

  @override
  Future<Uint8List?> loadBytes(String path) async {
    final normalizedPath = p.normalize(path);
    final bytes = await ctx.pathToFile[normalizedPath]?.readAsBytes();
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

  static Future<AssetImportResult> import(XFile file, AssetImportContext ctx) async {
    final gltfNormalizedPath = p.normalize(file.name);
    final resourceLoader = _GLTFImporterResourceLoader(ctx: ctx);

    final gltf = await GLTF.load(gltfNormalizedPath, resourceLoader: resourceLoader);
    if (gltf == null) return AssetImportResult.empty();

    while (SLEditor.modelPreviewGenerator == null) {
      await Future.delayed(Duration(milliseconds: 100));
    }
    final (thumbBytes, thumbMime) = await SLEditor.modelPreviewGenerator!.generateModelPreview(gltf.root, size: 256);

    final gltfUuid = Uuid().v4();
    final createInfos = <AssetCreateInfo>[];

    final consumed = <XFile>{};
    final redirects = <String, UUID>{};
    for (final loadedPath in resourceLoader.getLoadedPaths()) {
      if (loadedPath == gltfNormalizedPath) continue;

      final subFile = ctx.pathToFile[loadedPath]!;
      consumed.add(subFile);

      final uuid = Uuid().v4();
      redirects[loadedPath] = uuid;

      createInfos.add(
        AssetCreateInfo(
          uuid: uuid,
          parent: gltfUuid,
          name: p.basenameWithoutExtension(subFile.name),
          type: await Assets.inferAssetType(file, ctx),
          uploadFile: subFile,
        ),
      );
    }

    createInfos.add(
      AssetCreateInfo(
        uuid: gltfUuid,
        parent: ctx.directory,
        name: p.basenameWithoutExtension(file.name),
        type: .model,
        properties: redirects.isEmpty
            ? null
            : {
                'redirects': redirects,
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
