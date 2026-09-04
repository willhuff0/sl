import 'dart:async';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:sl_editor/client/assets/asset_blob_filesystem.dart';
import 'package:sl_editor/client/assets/asset_blob_transferer.dart';
import 'package:sl_editor/client/assets/shared_database.dart';
import 'package:sl_editor/client/client.dart';
import 'package:sl_editor/client/assets/local_asset_database.dart';
import 'package:sl_engine/logger.dart';
import 'package:sl_shared/sl_shared.dart';
import 'package:sqlite_crdt/sqlite_crdt.dart';

class AssetSystem {
  final CrdtSync _crdtSync;
  final SharedDatabase _sharedDatabase;
  final LocalAssetDatabase _localDatabase;
  final AssetBlobFilesystem _blobFilesystem;
  final AssetBlobTransferer _blobTransferer;

  AssetSystem._({
    required CrdtSync crdtSync,
    required SharedDatabase sharedDatabase,
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
      verbose: false,
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
      sharedDatabase: SharedDatabase(sharedDatabase),
      localDatabase: localDatabase,
      blobFilesystem: blobFilesystem,
      blobTransferer: blobTransferer,
    );
  }

  SharedDatabase get sharedDatabase => _sharedDatabase;

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
    if (_sharedDatabase.isBuiltinAsset(uuid)) {
      Logger.log('Tried to upload to a built-in asset $uuid', .warning);
      return;
    }
    return _blobTransferer.upload(uuid, file, offset: offset);
  }

  Future<void> ensureBlobsAvailable(Set<UUID> uuids) async {
    await Future.wait(uuids.map((uuid) => getAssetBlob(uuid, keepCopyInMemory: false)));
  }

  Completer? _getAssetBlobLock;
  Future<Uint8List?> getAssetBlob(UUID uuid, {bool keepCopyInMemory = true}) async {
    if (_sharedDatabase.isBuiltinAsset(uuid)) {
      final (exists, bytes) = await _sharedDatabase.getBuiltinAssetBlob(uuid);
      if (exists == false) {
        Logger.log(
          'Tried to get the blob for a builtin asset $uuid which does not exist.',
          .warning,
        );
        return null;
      }
      return bytes;
    }

    while (_getAssetBlobLock != null) {
      await _getAssetBlobLock?.future;
    }
    _getAssetBlobLock = Completer();

    // Store the future representing the ongoing request/download
    Future<Uint8List?>? resultFuture;

    try {
      final localEntry = await _localDatabase.getAsset(uuid);

      final activeDownload = await _blobTransferer.getActiveDownload(uuid);
      if (activeDownload != null) {
        // Asset download is alive and active
        if (keepCopyInMemory && !activeDownload.isKeepingCopyInMemory) {
          resultFuture = activeDownload.onComplete.then((_) => _blobFilesystem.getAssetBlobFromFile(uuid));
        } else {
          resultFuture = activeDownload.onComplete;
        }
      } else if (localEntry != null) {
        // Asset is tracked locally
        if (localEntry.downloadProgress != null) {
          // Asset download is in progress needs to be resumed
          final download = await _blobTransferer.requestDownload(
            uuid,
            offset: localEntry.downloadProgress!,
            keepCopyInMemory: keepCopyInMemory,
          );
          resultFuture = download?.onComplete;
        } else if (localEntry.blobSize != null) {
          // Asset is available locally
          var localBlobVersion = localEntry.blobVersion;
          if (localBlobVersion == null) {
            Logger.log(
              'The blob for asset $uuid has no local version number. Reacquiring...',
              .warning,
            );
            final download = await _blobTransferer.requestDownload(uuid, keepCopyInMemory: keepCopyInMemory);
            resultFuture = download?.onComplete;
          } else {
            final (exists, remoteBlobVersion) = await _sharedDatabase.getAssetBlobVersion(uuid);

            if (exists) {
              if (remoteBlobVersion == null) {
                Logger.log(
                  'Tried to load the blob for asset $uuid which has not been uploaded yet. The asset blob was incorrectly marked as locally available.',
                  .error,
                );
                resultFuture = Future.value(null);
              } else if (remoteBlobVersion > localBlobVersion) {
                // local file is out of date
                final download = await _blobTransferer.requestDownload(uuid, keepCopyInMemory: keepCopyInMemory);
                resultFuture = download?.onComplete;
              } else {
                // local file is up to date
                resultFuture = _blobFilesystem.getAssetBlobFromFile(uuid).then((bytes) async {
                  if (bytes != null) return bytes;

                  // file doesn't exist (this is a bug, redownload)
                  Logger.log(
                    'Tried to load the blob for asset $uuid from its OPFS file, which does not exist. The asset blob was incorrectly marked as locally available. Reacquiring...',
                    .warning,
                  );
                  final download = await _blobTransferer.requestDownload(uuid, keepCopyInMemory: keepCopyInMemory);
                  return download?.onComplete;
                });
              }
            } else {
              // asset has been deleted or was reverted by the server
              Logger.log(
                'Tried to load the blob for an asset \'$uuid\' which does not exist on the server.',
                .warning,
              );
              await _localDatabase.deleteAsset(uuid);
              resultFuture = Future.value(null);
            }
          }
        }
      } else {
        // Asset is not tracked locally
        final download = await _blobTransferer.requestDownload(uuid, keepCopyInMemory: keepCopyInMemory);
        resultFuture = download?.onComplete;
      }
    } finally {
      _getAssetBlobLock?.complete();
      _getAssetBlobLock = null;
    }

    return resultFuture;
  }
}
