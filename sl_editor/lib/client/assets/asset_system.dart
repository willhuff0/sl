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
  final Client _client;
  final CrdtSync _crdtSync;
  final SqliteCrdt _sharedDatabase;
  final LocalAssetDatabase _localDatabase;
  final AssetBlobFilesystem _blobFilesystem;
  final AssetBlobTransferer _blobTransferer;

  AssetSystem._({
    required Client client,
    required CrdtSync crdtSync,
    required SqliteCrdt sharedDatabase,
    required LocalAssetDatabase localDatabase,
    required AssetBlobFilesystem blobFilesystem,
    required AssetBlobTransferer blobTransferer,
  }) : _client = client,
       _crdtSync = crdtSync,
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
      client: client,
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
        await _blobTransferer.handleEndDownload(endOp.uuid);
        break;
      case PtpAssetBlobError error:
        Logger.log('[SERVER] Asset blob error: ${error.error}');
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
    DateTime? lastQuery;
    return _sharedDatabase
        .watch('SELECT uuid, blob_size, blob_updated_at FROM assets WHERE uuid = ?1', () => [uuid])
        .asyncMap((rows) async {
          if (rows.isEmpty) return null;

          final blobSize = rows.first['blob_size'] as int?;
          if (blobSize == null) return null;

          final blobUpdatedAtString = rows.first['blob_updated_at'] as String?;
          if (blobUpdatedAtString == null) return null;
          final blobUpdatedAt = DateTime.parse(blobUpdatedAtString);

          if (lastQuery == null || blobUpdatedAt.isAfter(lastQuery!)) {
            lastQuery = blobUpdatedAt;
            return await getAssetBlob(uuid);
          }

          return Uint8List(0);
        })
        .where((bytes) => bytes?.isNotEmpty ?? true);
  }

  Future<Uint8List?> getAssetBlob(UUID uuid, {bool keepCopyInMemory = true}) async {
    final localEntry = await _localDatabase.getAsset(uuid);

    if (localEntry != null) {
      // Asset is tracked locally

      if (localEntry.downloadProgress != null) {
        // Asset download is in progress, may need to be resumed

        final activeDownload = await _blobTransferer.getActiveDownload(uuid);
        if (activeDownload != null) {
          // Asset download is alive and active
          final bytes = await activeDownload.onComplete;

          if (keepCopyInMemory) {
            // active download keepCopyInMemory may not be true
            return bytes ?? _blobFilesystem.getAssetBlobFromFile(uuid);
          } else {
            return bytes;
          }
        }

        // Resume download
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
        var localUpdatedAt = localEntry.blobUpdatedAt;
        if (localUpdatedAt == null) {
          Logger.log(
            'The blob for asset $uuid has no local timestamp. Reacquiring...',
            .warning,
          );
          final download = await _blobTransferer.requestDownload(uuid, keepCopyInMemory: keepCopyInMemory);
          return download?.onComplete;
        }

        final rows = await _sharedDatabase.query(
          'SELECT uuid, blob_updated_at FROM assets WHERE uuid = ?1',
          [uuid],
        );
        if (rows.isEmpty) {
          Logger.log(
            'Tried to load the blob for asset $uuid, which does not exist. The asset blob was incorrectly marked as locally available.',
            .error,
          );
          return null;
        }
        final remoteUpdatedAtEncoded = rows.first['blob_updated_at'] as String?;
        if (remoteUpdatedAtEncoded == null) {
          Logger.log(
            'Tried to load the blob for asset $uuid which has not been uploaded yet. The asset blob was incorrectly marked as locally available.',
            .error,
          );
          return null;
        }
        final remoteUpdatedAt = DateTime.parse(remoteUpdatedAtEncoded);
        if (remoteUpdatedAt.isAfter(localUpdatedAt)) {
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
  }
}
