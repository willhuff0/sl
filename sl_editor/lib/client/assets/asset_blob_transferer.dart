import 'dart:async';
import 'dart:js_interop';
import 'dart:math';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:sl_editor/client/assets/asset_blob_filesystem.dart';
import 'package:sl_editor/client/assets/local_asset_database.dart';
import 'package:sl_editor/client/client.dart';
import 'package:sl_engine/logger.dart';
import 'package:sl_shared/sl_shared.dart';
import 'package:sqlite_crdt/sqlite_crdt.dart';
import 'package:uuid/uuid.dart';
import 'package:web/web.dart' as web;

final _tempProgressChangedController = StreamController<(UUID, AssetTransferProgress)>.broadcast();
final tempProgressChanged = _tempProgressChangedController.stream;

class AssetTransferProgress {
  final int byteLength;
  final int bytesCompleted;
  final double progress;

  AssetTransferProgress({
    required this.byteLength,
    required this.bytesCompleted,
    required this.progress,
  });
}

class UploadOperation {
  final UUID uuid;
  final int offset;
  final int size;

  var _completed = false;

  final _completer = Completer<void>();
  final _progressController = StreamController<AssetTransferProgress>.broadcast();
  late final Stream<AssetTransferProgress> progressStream;

  UploadOperation({
    required this.uuid,
    required this.offset,
    required this.size,
  }) {
    progressStream = _progressController.stream;
  }

  Future<void> get onComplete => _completer.future;

  void addProgress(AssetTransferProgress progress) {
    _progressController.add(progress);
    _tempProgressChangedController.add((uuid, progress));
  }

  Future<void> finish() async {
    if (_completed) return;
    _completed = true;

    _progressController.add(
      AssetTransferProgress(
        byteLength: size - offset,
        bytesCompleted: size - offset,
        progress: 1.0,
      ),
    );
    _tempProgressChangedController.add((
      uuid,
      AssetTransferProgress(
        byteLength: size - offset,
        bytesCompleted: size - offset,
        progress: 1.0,
      ),
    ));
    await _progressController.close();
    _completer.complete();
  }
}

class PendingDownloadOperation {
  final Completer<DownloadOperation> completer;
  final bool keepCopyInMemory;
  final int offset;

  PendingDownloadOperation({
    required this.completer,
    required this.keepCopyInMemory,
    required this.offset,
  });
}

class DownloadOperation {
  final UUID uuid;
  final int offset;
  final int size;

  final web.FileSystemWritableFileStream _sink;

  final _completer = Completer<Uint8List?>();
  final _progressController = StreamController<AssetTransferProgress>.broadcast();
  late final Stream<AssetTransferProgress> progressStream;

  BytesBuilder? _inMemoryView;

  DownloadOperation({
    required this.uuid,
    required this.offset,
    required this.size,
    required web.FileSystemWritableFileStream sink,
    required bool keepCopyInMemory,
  }) : _sink = sink {
    progressStream = _progressController.stream;
    if (keepCopyInMemory) {
      _inMemoryView = BytesBuilder(copy: false);
    }
  }
  static Future<DownloadOperation> openFile({
    required UUID uuid,
    required int offset,
    required int size,
    required web.FileSystemFileHandle file,
    required bool keepCopyInMemory,
  }) async {
    final sink = await file
        .createWritable(
          web.FileSystemCreateWritableOptions(
            keepExistingData: true,
          ),
        )
        .toDart;
    await sink.truncate(size).toDart;
    await sink.seek(offset).toDart;
    return DownloadOperation(
      uuid: uuid,
      offset: offset,
      size: size,
      sink: sink,
      keepCopyInMemory: keepCopyInMemory,
    );
  }

  var _bytesReceived = 0;

  Future<Uint8List?> get onComplete => _completer.future;

  Future<int> addChunk(Uint8List chunk) async {
    _inMemoryView?.add(chunk);
    _bytesReceived += chunk.length;
    await _sink.write(chunk.toJS).toDart;
    _progressController.add(
      AssetTransferProgress(
        byteLength: size - offset,
        bytesCompleted: _bytesReceived,
        progress: _bytesReceived / (size - offset),
      ),
    );
    _tempProgressChangedController.add((
      uuid,
      AssetTransferProgress(
        byteLength: size - offset,
        bytesCompleted: _bytesReceived,
        progress: _bytesReceived / (size - offset),
      ),
    ));
    return _bytesReceived;
  }

  Future<void> finish() async {
    _progressController.add(
      AssetTransferProgress(
        byteLength: size - offset,
        bytesCompleted: size - offset,
        progress: 1.0,
      ),
    );
    _tempProgressChangedController.add((
      uuid,
      AssetTransferProgress(
        byteLength: size - offset,
        bytesCompleted: size - offset,
        progress: 1.0,
      ),
    ));
    await _progressController.close();
    await _sink.close().toDart;
    _completer.complete(_inMemoryView?.takeBytes());
    _inMemoryView = null;
  }
}

class AssetBlobTransferer {
  final Client _client;
  final SqliteCrdt _sharedDatabase;
  final LocalAssetDatabase _localDatabase;
  final AssetBlobFilesystem _blobFilesystem;

  final _pendingDownloads = <UUID, PendingDownloadOperation>{};
  final _downloads = <UUID, DownloadOperation>{};
  final _uploads = <UUID, UploadOperation>{};

  AssetBlobTransferer({
    required Client client,
    required SqliteCrdt sharedDatabase,
    required LocalAssetDatabase localDatabase,
    required AssetBlobFilesystem blobFilesystem,
  }) : _client = client,
       _sharedDatabase = sharedDatabase,
       _localDatabase = localDatabase,
       _blobFilesystem = blobFilesystem;

  Future<void> upload(UUID uuid, XFile file, {int offset = 0}) async {
    final size = await file.length();

    if (_uploads.containsKey(uuid)) {
      Logger.log(
        'Tried to start an upload of the blob for asset $uuid while it was already uploading.',
        .error,
      );
      return;
    }
    web.FileSystemWritableFileStream? cacheSink;
    try {
      final upload = _uploads[uuid] = UploadOperation(
        uuid: uuid,
        offset: offset,
        size: size,
      );

      int blobVersion;
      {
        final rows = await _sharedDatabase.query(
          'SELECT blob_version FROM assets WHERE uuid = ?1 AND is_deleted = 0;',
          [uuid],
        );
        if (rows.isEmpty) {
          Logger.log(
            'Tried to start an upload of the blob for asset $uuid which does not exist.',
            .error,
          );
          return;
        }
        final version = rows.first['blob_version'] as int?;
        blobVersion = version ?? 0;
      }

      _client.send(
        PtpAssetBlobStart(
          uuid: uuid,
          offset: offset,
          size: size,
        ),
      );
      try {
        final cacheFile = await _blobFilesystem.getFileOfAssetBlob(uuid, create: true);
        cacheSink = await cacheFile
            .createWritable(
              web.FileSystemCreateWritableOptions(
                keepExistingData: true,
              ),
            )
            .toDart;
        await cacheSink.truncate(size).toDart;
        await cacheSink.seek(offset).toDart;

        await for (final fileChunk in file.openRead(offset)) {
          await cacheSink.write(fileChunk.toJS).toDart;

          for (var i = 0; i < fileChunk.length;) {
            // recreate every time to avoid websocket queue related problems
            final networkBuffer = Uint8List(assetBlobChunkSize + 16); // prepended with uuid
            Uuid.parse(uuid, buffer: networkBuffer);

            final networkChunkLength = min(fileChunk.length - i, assetBlobChunkSize);
            if (networkChunkLength <= 0) break;

            final networkChunk = Uint8List.sublistView(fileChunk, i, i + networkChunkLength);
            networkBuffer.setRange(16, 16 + networkChunk.length, networkChunk);

            _client.sendBinary(Uint8List.sublistView(networkBuffer, 0, networkChunkLength + 16));

            i += networkChunkLength;
          }
        }

        await upload.onComplete; // wait for server to trigger via handleUploadProgress

        final rows = await _sharedDatabase.query(
          'SELECT blob_version FROM assets WHERE uuid = ?1 AND is_deleted = 0;',
          [uuid],
        );
        if (rows.isEmpty) {
          Logger.log(
            'Asset $uuid was deleted while it was uploading.',
            .error,
          );
          return;
        }
        final version = rows.first['blob_version'] as int?;
        blobVersion = (version ?? -1) + 1;

        await _localDatabase.setAssetBlobSizeAndClearDownloadProgress(uuid, size, blobVersion);
      } finally {
        _client.send(
          PtpAssetBlobEnd(
            uuid: uuid,
            version: blobVersion,
          ),
        );
      }
    } finally {
      await cacheSink?.close().toDart;
      await _uploads.remove(uuid)?.finish();
    }
  }

  Future<void> handleUploadProgress(UUID uuid, int bytesReceived) async {
    final upload = _uploads[uuid];
    if (upload == null) {
      Logger.log(
        'Server send a progress notification for an upload of the blob for asset $uuid while an upload was not in progress.',
        .error,
      );
      return;
    }
    if (bytesReceived >= upload.size - upload.offset) {
      await upload.finish();
    } else {
      upload.addProgress(
        AssetTransferProgress(
          byteLength: upload.size - upload.offset,
          bytesCompleted: bytesReceived,
          progress: bytesReceived / (upload.size - upload.offset),
        ),
      );
    }
  }

  Future<DownloadOperation?> getActiveDownload(UUID uuid) async {
    final pendingDownload = _pendingDownloads[uuid];
    if (pendingDownload != null) {
      return pendingDownload.completer.future;
    }

    return _downloads[uuid];
  }

  Future<DownloadOperation?> requestDownload(
    UUID uuid, {
    required bool keepCopyInMemory,
    int offset = 0,
  }) async {
    if (_uploads.containsKey(uuid)) {
      Logger.log(
        'Tried to start a download of the blob for asset $uuid while it was still uploading.',
        .error,
      );
      return null;
    }
    if (_pendingDownloads.containsKey(uuid)) {
      Logger.log(
        'Tried to start a download of the blob for asset $uuid while the download was already pending.',
        .error,
      );
      return null;
    }
    if (_downloads.containsKey(uuid)) {
      Logger.log(
        'Tried to start a download of the blob for asset $uuid while the download was already in progress.',
        .error,
      );
      return null;
    }
    final pendingDownload = _pendingDownloads[uuid] = PendingDownloadOperation(
      completer: Completer(),
      keepCopyInMemory: keepCopyInMemory,
      offset: offset,
    );

    try {
      final rows = await _sharedDatabase.query(
        'SELECT uuid, blob_size FROM assets WHERE uuid = ?1 AND is_deleted = 0',
        [uuid],
      );
      if (rows.isEmpty) {
        Logger.log(
          'Tried to download the blob for asset $uuid, which does not exist.',
          .error,
        );
        _pendingDownloads.remove(uuid);
        return null;
      }
      final blobSize = rows.first['blob_size'] as int?;
      if (blobSize == null) {
        Logger.log(
          'Tried to download the blob for asset $uuid, which does not have a blob.',
          .error,
        );
        _pendingDownloads.remove(uuid);
        return null;
      }

      if (offset >= blobSize) {
        Logger.log(
          'Tried to resume a download of the blob for asset $uuid which has size $blobSize bytes starting from byte $offset.',
          .error,
        );
        _pendingDownloads.remove(uuid);
        return null;
      }

      await _localDatabase.setAssetDownloadProgress(uuid, 0);

      _client.send(
        CtsRequestAssetBlob(
          uuid: uuid,
          offset: offset,
        ),
      );
      return await pendingDownload.completer.future;
    } catch (_) {
      _pendingDownloads.remove(uuid);
      rethrow;
    }
  }

  Future<void> handleStartDownload(UUID uuid, int offset, int size) async {
    try {
      final pendingDownload = _pendingDownloads[uuid];
      if (pendingDownload == null) {
        Logger.log(
          'Server initiated a download of the blob for asset $uuid which was not requested.',
          .error,
        );
        return;
      }
      if (pendingDownload.offset != offset) {
        Logger.log(
          'Server initiated a download of the blob for asset $uuid with a different offset than requested. Asked for ${pendingDownload.offset}. Got $offset.',
          .error,
        );
        return;
      }

      if (_downloads.containsKey(uuid)) {
        Logger.log(
          'Server initiated a download of the blob for asset $uuid while the download was already both pending and in progress. Something went terribly wrong.',
          .error,
        );
        return;
      }
      final file = await _blobFilesystem.getFileOfAssetBlob(uuid, create: true);
      final download = _downloads[uuid] = await DownloadOperation.openFile(
        uuid: uuid,
        offset: offset,
        size: size,
        file: file,
        keepCopyInMemory: pendingDownload.keepCopyInMemory,
      );
      pendingDownload.completer.complete(download);
    } finally {
      _pendingDownloads.remove(uuid);
    }
  }

  Future<void> handleBinary(Uint8List bytes) async {
    final uuid = Uuid.unparse(Uint8List.sublistView(bytes, 0, 16));

    final download = _downloads[uuid];
    if (download == null) {
      Logger.log(
        'Server sent a chunk of the blob for asset $uuid which was not requested.',
        .error,
      );
      return;
    }

    final bytesCompleted = await download.addChunk(Uint8List.sublistView(bytes, 16));
    await _localDatabase.setAssetDownloadProgress(uuid, download.offset + bytesCompleted);
  }

  Future<void> handleEndDownload(UUID uuid, int version) async {
    try {
      final download = _downloads[uuid];
      if (download == null) {
        Logger.log(
          'Server finalized a download of the blob for asset $uuid which was not requested.',
          .error,
        );
        return;
      }

      await download.finish();
      await _localDatabase.setAssetBlobSizeAndClearDownloadProgress(uuid, download.size, version);
    } finally {
      _downloads.remove(uuid);
    }
  }
}
