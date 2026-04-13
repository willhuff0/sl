import 'dart:js_interop';
import 'dart:typed_data';

import 'package:sl_shared/sl_shared.dart';
import 'package:web/web.dart' as web;

class AssetBlobFilesystem {
  final web.FileSystemDirectoryHandle _blobsRoot;

  AssetBlobFilesystem._(this._blobsRoot);
  static Future<AssetBlobFilesystem> open(UUID projectId) async {
    final originPrivateFileSystem = await web.window.navigator.storage.getDirectory().toDart;
    final root = await originPrivateFileSystem
        .getDirectoryHandle(
          projectId,
          web.FileSystemGetDirectoryOptions(
            create: true,
          ),
        )
        .toDart;
    final blobsRoot = await root
        .getDirectoryHandle(
          'blobs',
          web.FileSystemGetDirectoryOptions(
            create: true,
          ),
        )
        .toDart;
    return AssetBlobFilesystem._(blobsRoot);
  }

  Future<web.FileSystemFileHandle> getFileOfAssetBlob(UUID uuid, {bool create = false}) async {
    return await _blobsRoot
        .getFileHandle(
          uuid,
          web.FileSystemGetFileOptions(
            create: create,
          ),
        )
        .toDart;
  }

  Future<Uint8List?> getAssetBlobFromFile(UUID uuid) async {
    try {
      final file = await (await getFileOfAssetBlob(uuid, create: false)).getFile().toDart;
      if (file.size != 0) {
        final arrayBuffer = (await file.arrayBuffer().toDart).toDart;
        return arrayBuffer.asUint8List();
      }
    } catch (_) {}
    return null;
  }
}
