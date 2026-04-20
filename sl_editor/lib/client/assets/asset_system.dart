import 'dart:async';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:sl_editor/client/assets/asset_blob_filesystem.dart';
import 'package:sl_editor/client/assets/asset_blob_transferer.dart';
import 'package:sl_editor/client/client.dart';
import 'package:sl_editor/client/assets/local_asset_database.dart';
import 'package:sl_engine/logger.dart';
import 'package:sl_shared/sl_shared.dart';
import 'package:sqlite_crdt/sqlite_crdt.dart';

class AssetSystem {
  final CrdtSync _crdtSync;
  final SqliteCrdt _sharedDatabase;
  final LocalAssetDatabase _localDatabase;
  final AssetBlobFilesystem _blobFilesystem;
  final AssetBlobTransferer _blobTransferer;

  AssetSystem._({
    required CrdtSync crdtSync,
    required SqliteCrdt sharedDatabase,
    required LocalAssetDatabase localDatabase,
    required AssetBlobFilesystem blobFilesystem,
    required AssetBlobTransferer blobTransferer,
  }) : _crdtSync = crdtSync,
       _sharedDatabase = sharedDatabase,
       _localDatabase = localDatabase,
       _blobFilesystem = blobFilesystem,
       _blobTransferer = blobTransferer;
  static Future<AssetSystem> create(Client client, SqliteCrdt sharedDatabase, UUID projectId) async {
    final crdtSync = CrdtSync.client(
      sharedDatabase,
      send: (message) => client.send(PtpCrdtSync(message: message)),
      verbose: true,
    );
    final localDatabase = await LocalAssetDatabase.open(projectId);
    final blobFilesystem = await AssetBlobFilesystem.open(projectId);
    final blobTransferer = AssetBlobTransferer(
      client: client,
      sharedDatabase: sharedDatabase,
      localDatabase: localDatabase,
      blobFilesystem: blobFilesystem,
    );
    return AssetSystem._(
      crdtSync: crdtSync,
      sharedDatabase: sharedDatabase,
      localDatabase: localDatabase,
      blobFilesystem: blobFilesystem,
      blobTransferer: blobTransferer,
    );
  }

  SqliteCrdt get sharedDatabase => _sharedDatabase;

  Future<bool> handleMessage(Message message) async {
    switch (message) {
      case PtpCrdtSync crdtSync:
        _crdtSync.syncSocket.receive(crdtSync.message);
        break;
      case PtpAssetBlobStart startOp:
        await _blobTransferer.handleStartDownload(startOp.uuid, startOp.offset, startOp.size);
        break;
      case StcAssetBlobProgress progress:
        await _blobTransferer.handleUploadProgress(progress.uuid, progress.bytesReceived);
      case PtpAssetBlobEnd endOp:
        await _blobTransferer.handleEndDownload(endOp.uuid, endOp.version);
        break;
      case PtpAssetBlobError error:
        Logger.log('[SERVER] ${error.error}', .error);
        break;
      default:
        return false;
    }
    return true;
  }

  Future<void> handleBinary(Uint8List bytes) async {
    return _blobTransferer.handleBinary(bytes);
  }

  Future<void> upload(UUID uuid, XFile file, {int offset = 0}) async {
    return _blobTransferer.upload(uuid, file, offset: offset);
  }

  Future<void> ensureBlobsAvailable(Set<UUID> uuids) async {
    await Future.wait(uuids.map((uuid) => getAssetBlob(uuid, keepCopyInMemory: false)));
  }

  Stream<Uint8List?> watchAssetBlob(UUID uuid) {
    int? lastBlobVersion;
    return _sharedDatabase
        .watch('SELECT uuid, blob_size, blob_version FROM assets WHERE uuid = ?1 AND is_deleted = 0', () => [uuid])
        .asyncMap((rows) async {
          if (rows.isEmpty) return null;

          final blobSize = rows.first['blob_size'] as int?;
          if (blobSize == null) return null;

          final blobVersion = rows.first['blob_version'] as int?;
          if (blobVersion == null) return null;

          if (lastBlobVersion == null || blobVersion > lastBlobVersion!) {
            lastBlobVersion = blobVersion;
            return await getAssetBlob(uuid);
          }

          return Uint8List(0);
        })
        .where((bytes) => bytes?.isNotEmpty ?? true);
  }

  Completer? _getAssetBlobLock;
  Future<Uint8List?> getAssetBlob(UUID uuid, {bool keepCopyInMemory = true}) async {
    while (_getAssetBlobLock != null) {
      await _getAssetBlobLock?.future;
    }
    _getAssetBlobLock = Completer();
    try {
      final localEntry = await _localDatabase.getAsset(uuid);

      final activeDownload = await _blobTransferer.getActiveDownload(uuid);
      if (activeDownload != null) {
        // Asset download is alive and active

        // active download keepCopyInMemory may not be true
        if (keepCopyInMemory && !activeDownload.isKeepingCopyInMemory) {
          return activeDownload.onComplete.then((_) => _blobFilesystem.getAssetBlobFromFile(uuid));
        } else {
          return activeDownload.onComplete;
        }
      }

      if (localEntry != null) {
        // Asset is tracked locally

        if (localEntry.downloadProgress != null) {
          // Asset download is in progress needs to be resumed
          final download = await _blobTransferer.requestDownload(
            uuid,
            offset: localEntry.downloadProgress!,
            keepCopyInMemory: keepCopyInMemory,
          );
          return download?.onComplete;
        }

        if (localEntry.blobSize != null) {
          // Asset is available locally

          // check if remote blob is newer
          var localBlobVersion = localEntry.blobVersion;
          if (localBlobVersion == null) {
            Logger.log(
              'The blob for asset $uuid has no local version number. Reacquiring...',
              .warning,
            );
            final download = await _blobTransferer.requestDownload(uuid, keepCopyInMemory: keepCopyInMemory);
            return download?.onComplete;
          }

          final rows = await _sharedDatabase.query(
            'SELECT uuid, blob_version FROM assets WHERE uuid = ?1 AND is_deleted = 0',
            [uuid],
          );
          if (rows.isEmpty) {
            Logger.log(
              'Tried to load the blob for asset $uuid, which does not exist. The asset blob was incorrectly marked as locally available.',
              .error,
            );
            return null;
          }
          final remoteBlobVersion = rows.first['blob_version'] as int?;
          if (remoteBlobVersion == null) {
            Logger.log(
              'Tried to load the blob for asset $uuid which has not been uploaded yet. The asset blob was incorrectly marked as locally available.',
              .error,
            );
            return null;
          }
          if (remoteBlobVersion > localBlobVersion) {
            // local file is out of date

            final download = await _blobTransferer.requestDownload(uuid, keepCopyInMemory: keepCopyInMemory);
            return download?.onComplete;
          }

          // local file is up to date
          final bytes = await _blobFilesystem.getAssetBlobFromFile(uuid);
          if (bytes != null) return bytes;

          // file doesn't exist (this is a bug, redownload)
          Logger.log(
            'Tried to load the blob for asset $uuid from its OPFS file, which does not exist. The asset blob was incorrectly marked as locally available. Reacquiring...',
            .warning,
          );
          final download = await _blobTransferer.requestDownload(uuid, keepCopyInMemory: keepCopyInMemory);
          return download?.onComplete;
        }
      }

      // Asset is not tracked locally

      final download = await _blobTransferer.requestDownload(uuid, keepCopyInMemory: keepCopyInMemory);
      return download?.onComplete;
    } finally {
      _getAssetBlobLock?.complete();
      _getAssetBlobLock = null;
    }
  }
}
