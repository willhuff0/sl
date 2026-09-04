import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:sl_editor/assets.dart';

final class _ArchiveUploadFile implements UploadFile {
  final Uint8List _bytes;

  @override
  final String path;
  @override
  final String name;
  @override
  final String extension;

  @override
  final int size;

  _ArchiveUploadFile({
    required Uint8List bytes,
    required this.path,
  }) : _bytes = bytes,
       name = p.basenameWithoutExtension(path),
       extension = p.extension(path).toLowerCase(),
       size = bytes.length;

  @override
  Uint8List readAsBytes() {
    return _bytes;
  }

  @override
  Stream<Uint8List> openRead(int offset, int chunkSize) async* {
    var currentOffset = offset;

    while (currentOffset < size) {
      final end = (currentOffset + chunkSize < size) ? currentOffset + chunkSize : size;

      yield Uint8List.sublistView(_bytes, currentOffset, end);

      currentOffset += chunkSize;
    }
  }
}

class ArchiveImporter {
  static final registration = AssetImporter(
    extensions: ['.zip', '.tar', '.gz', '.tgz', '.bz2', '.tbz', '.tbz2', '.xz', '.txz'],
    priority: 100,
    import: import,
    inferAssetType: null,
  );

  static Archive Function(List<int>)? _getDecoder(String extension) {
    return switch (extension) {
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

  static Future<AssetImportResult> import(UploadFile file, AssetImportContext ctx) async {
    final decoder = _getDecoder(file.extension)!;
    final bytes = await file.readAsBytes();
    final archive = decoder(bytes);

    final files = <_ArchiveUploadFile>[];
    for (final entry in archive) {
      if (!entry.isFile) continue;

      final bytes = entry.readBytes();
      if (bytes == null) continue;
      final path = entry.name;

      files.add(
        _ArchiveUploadFile(
          bytes: bytes,
          path: path,
        ),
      );
    }
    await Assets.import(ctx.directory, files);

    return AssetImportResult.empty();
  }
}
