import 'package:archive/archive.dart';
import 'package:cross_file/cross_file.dart';
import 'package:path/path.dart' as p;
import 'package:sl_editor/assets.dart';

class ArchiveImporter {
  static final registration = AssetImporter(
    extensions: ['.zip', '.tar', '.gz', '.tgz', '.bz2', '.tbz', '.tbz2', '.xz', '.txz'],
    priority: 100,
    import: import,
    inferAssetType: null,
  );

  static Archive Function(List<int>)? _getDecoder(String name) {
    return switch (p.extension(name).toLowerCase()) {
      '.zip' => ZipDecoder().decodeBytes,
      '.tar' => TarDecoder().decodeBytes,
      '.gz' => (bytes) => TarDecoder().decodeBytes(GZipDecoder().decodeBytes(bytes)),
      '.tgz' => (bytes) => TarDecoder().decodeBytes(GZipDecoder().decodeBytes(bytes)),
      '.bz2' => (bytes) => TarDecoder().decodeBytes(BZip2Decoder().decodeBytes(bytes)),
      '.tbz' => (bytes) => TarDecoder().decodeBytes(BZip2Decoder().decodeBytes(bytes)),
      '.tbz2' => (bytes) => TarDecoder().decodeBytes(BZip2Decoder().decodeBytes(bytes)),
      '.xz' => (bytes) => TarDecoder().decodeBytes(XZDecoder().decodeBytes(bytes)),
      '.txz' => (bytes) => TarDecoder().decodeBytes(XZDecoder().decodeBytes(bytes)),
      _ => null,
    };
  }

  static Future<AssetImportResult> import(XFile file, AssetImportContext ctx) async {
    final decoder = _getDecoder(file.name)!;
    final bytes = await file.readAsBytes();
    final archive = decoder(bytes);

    final files = <XFile>[];
    for (final entry in archive) {
      if (!entry.isFile) continue;

      final name = entry.name;
      final length = entry.size;
      final bytes = entry.readBytes();
      if (bytes == null) continue;
      final lastModified = entry.lastModDateTime;

      files.add(
        XFile(
          name,
          name: name,
          length: length,
          bytes: bytes,
          lastModified: lastModified,
        ),
      );
    }
    await Assets.import(ctx.directory, files);

    return AssetImportResult.empty();
  }
}
