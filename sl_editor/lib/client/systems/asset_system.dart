import 'dart:async';
import 'dart:js_interop';
import 'dart:math';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:sembast_web/sembast_web.dart';
import 'package:sl_editor/client/client.dart';
import 'package:sl_editor/client/file_system.dart';
import 'package:sl_editor/client/objects/asset.dart';
import 'package:sl_editor/client/state_tracker.dart';
import 'package:sl_engine/logger.dart';
import 'package:sl_shared/sl_shared.dart';
import 'package:uuid/uuid.dart';
import 'package:web/web.dart' as web;

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
  final int length;
  final int size;

  final _completer = Completer<void>();
  final _progressController = StreamController<AssetTransferProgress>.broadcast();
  late final Stream<AssetTransferProgress> progressStream;

  UploadOperation({
    required this.uuid,
    required this.offset,
    required this.length,
    required this.size,
  }) {
    progressStream = _progressController.stream;
  }

  Future<void> get onComplete => _completer.future;

  void addProgress(AssetTransferProgress progress) {
    _progressController.add(progress);
  }

  Future<void> finish() async {
    _progressController.add(
      AssetTransferProgress(
        byteLength: length,
        bytesCompleted: length,
        progress: 1.0,
      ),
    );
    await _progressController.close();
    _completer.complete();
  }
}

class DownloadOperation {
  final UUID uuid;
  final int offset;
  final int length;
  final int size;

  final web.FileSystemWritableFileStream _sink;

  final _completer = Completer<Uint8List?>();
  final _progressController = StreamController<AssetTransferProgress>.broadcast();
  late final Stream<AssetTransferProgress> progressStream;

  BytesBuilder? _inMemoryView;

  DownloadOperation({
    required this.uuid,
    required this.offset,
    required this.length,
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
    required int length,
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
      length: length,
      size: size,
      sink: sink,
      keepCopyInMemory: keepCopyInMemory,
    );
  }

  var _bytesReceived = 0;

  Future<Uint8List?> get onComplete => _completer.future;

  Future<void> addChunk(Uint8List chunk) async {
    _inMemoryView?.add(chunk);
    _bytesReceived += chunk.length;
    await _sink.write(chunk.toJS).toDart;
    _progressController.add(
      AssetTransferProgress(
        byteLength: length,
        bytesCompleted: _bytesReceived,
        progress: _bytesReceived / length,
      ),
    );
  }

  Future<void> finish() async {
    _progressController.add(
      AssetTransferProgress(
        byteLength: length,
        bytesCompleted: length,
        progress: 1.0,
      ),
    );
    await _progressController.close();
    await _sink.close().toDart;
    _completer.complete(_inMemoryView?.takeBytes());
    _inMemoryView = null;
  }
}

class AssetSystem {
  final _dbStore = stringMapStoreFactory.store();
  final _dbFactory = databaseFactoryWeb;

  final Client client;
  late final StateTracker<TrackedAsset> stateTracker;

  final _onAssetCountChangedController = StreamController.broadcast();
  late final Stream onAssetCountChanged;

  AssetSystem(this.client) {
    stateTracker = StateTracker<TrackedAsset>(
      .asset,
      constructors: {
        TrackedAsset.objectClass: TrackedAsset.new,
      },
      onObjectAdded: _onAssetAdded,
      onObjectRemoved: _onAssetRemoved,
    );
    onAssetCountChanged = _onAssetCountChangedController.stream;
  }

  UUID? _subscribedDirectory;

  final Map<UUID, (Completer<DownloadOperation>, bool keepCopyInMemory)> pendingDownloads = {};
  final Map<UUID, DownloadOperation> downloads = {};
  final Map<UUID, UploadOperation> uploads = {};
  final Set<UUID> _locked = {};

  final Map<UUID?, List<FoldedAsset>> _directoryToFoldedAssets = {};

  Future<void> dispose() async {
    await _db?.close();
  }

  void _onAssetAdded(TrackedAsset asset) {
    _onAssetCountChangedController.add(null);
  }

  void _onAssetRemoved(TrackedAsset asset) {
    _onAssetCountChangedController.add(null);
  }

  List<FoldedAsset> getAssetsInDirectory(UUID? directory) {
    return _directoryToFoldedAssets[directory] ?? [];
  }

  Database? _db;
  Future<Database> _getDatabase() async {
    return _db ??= await _dbFactory.openDatabase('assets');
  }

  web.FileSystemDirectoryHandle? _blobsRoot;
  Future<web.FileSystemDirectoryHandle> _getBlobsRoot() async {
    return _blobsRoot ??= await SlFileSystem.root
        .getDirectoryHandle(
          'blobs',
          web.FileSystemGetDirectoryOptions(
            create: true,
          ),
        )
        .toDart;
  }

  Future<web.FileSystemFileHandle> _getFileOfAssetBlob(UUID uuid) async {
    return await (await _getBlobsRoot())
        .getFileHandle(
          uuid,
          web.FileSystemGetFileOptions(
            create: true,
          ),
        )
        .toDart;
  }

  Future<Uint8List?> getAssetBlob(UUID uuid) async {
    {
      // may have different offset and length
      final pendingDownload = pendingDownloads[uuid];
      if (pendingDownload != null) {
        final downloadOperation = await pendingDownload.$1.future;
        return downloadOperation.onComplete;
      }

      final downloadOperation = downloads[uuid];
      if (downloadOperation != null) {
        return downloadOperation.onComplete;
      }
    }

    final db = await _getDatabase();
    final entry = await _dbStore.record(uuid).get(db);
    if (entry != null && entry['isBlobLocal'] == true) {
      final file = await (await _getFileOfAssetBlob(uuid)).getFile().toDart;
      final arrayBuffer = (await file.arrayBuffer().toDart).toDart;
      return arrayBuffer.asUint8List();
    } else {
      final downloadOperation = await downloadAssetBlob(uuid, keepCopyInMemory: true);
      if (downloadOperation == null) return null;
      return downloadOperation.onComplete;
    }
  }

  Future<DownloadOperation?> downloadAssetBlob(
    UUID uuid, {
    int offset = 0,
    int length = -1,
    bool keepCopyInMemory = false,
  }) async {
    if (_locked.contains(uuid)) {
      Logger.log(
        '[ASSET] Tried to download to an asset blob which was locked.',
        .error,
      );
      return null;
    }
    _locked.add(uuid);

    final pendingDownload = pendingDownloads[uuid] = (Completer(), keepCopyInMemory);

    client.send(
      CtsRequestAssetBlob(
        uuid: uuid,
        offset: offset,
        length: length,
      ),
    );

    return pendingDownload.$1.future;
  }

  void uploadAssetBlob(UUID uuid, XFile file, {int offset = 0, int? length}) async {
    if (_locked.contains(uuid)) {
      Logger.log(
        '[ASSET] Tried to upload to an asset blob which was locked.',
        .error,
      );
      return;
    }
    _locked.add(uuid);

    web.FileSystemWritableFileStream? cacheSink;
    try {
      final fileSize = await file.length();
      length ??= fileSize - offset;
      final upload = uploads[uuid] = UploadOperation(
        uuid: uuid,
        offset: offset,
        length: length,
        size: fileSize,
      );

      final cacheFile = await _getFileOfAssetBlob(uuid);
      cacheSink = await cacheFile
          .createWritable(
            web.FileSystemCreateWritableOptions(
              keepExistingData: true,
            ),
          )
          .toDart;
      await cacheSink.truncate(await file.length()).toDart;
      await cacheSink.seek(offset).toDart;

      var bytesCompleted = 0;
      await for (final fileChunk in file.openRead(offset, length)) {
        await cacheSink.write(fileChunk.toJS).toDart;

        for (var i = 0; i < fileChunk.length;) {
          final networkChunkLength = min(fileChunk.length - i, assetBlobChunkSize);
          if (networkChunkLength <= 0) break;

          final networkChunk = fileChunk.buffer.asUint8List(i, networkChunkLength);
          client.sendBinary(networkChunk);

          i += networkChunkLength;
        }

        bytesCompleted += fileChunk.length;
        upload.addProgress(
          AssetTransferProgress(
            byteLength: length,
            bytesCompleted: bytesCompleted,
            progress: bytesCompleted / length,
          ),
        );
      }

      final db = await _getDatabase();
      await _dbStore.record(uuid).put(db, {
        'uuid': uuid,
        'isBlobLocal': true,
      }, merge: true);
    } finally {
      await cacheSink?.close().toDart;
      await uploads.remove(uuid)?.finish();
      _locked.remove(uuid);
    }
  }

  void listenToDirectory(UUID? directory) {
    _subscribedDirectory = directory;
    client.send(
      CtsListenToAssetDirectory(
        directory: directory,
      ),
    );
  }

  Future<bool> handleMessage(Message message) async {
    switch (message) {
      case PtpAssetBlobStart startOp:
        await _startDownloadOp(startOp.uuid, startOp.offset, startOp.length, startOp.size);
        break;
      case PtpAssetBlobEnd endOp:
        await _endDownloadOp(endOp.uuid);
        break;
      case StcAssetBlobProgress progress:
        await _onUploadProgress(progress.uuid, progress.bytesReceived);
        break;
      default:
        return false;
    }
    return true;
  }

  Future<void> _startDownloadOp(UUID uuid, int offset, int length, int size) async {
    final pendingDownload = pendingDownloads[uuid];
    if (pendingDownload == null) {
      client.send(
        PtpAssetBlobError(
          uuid: uuid,
          error: .operationNotStarted,
        ),
      );
      return;
    }

    final file = await _getFileOfAssetBlob(uuid);
    final downloadOperation = downloads[uuid] = await DownloadOperation.openFile(
      uuid: uuid,
      offset: offset,
      length: length,
      size: size,
      file: file,
      keepCopyInMemory: pendingDownload.$2,
    );

    pendingDownload.$1.complete(downloadOperation);
  }

  Future<void> handleBinary(Uint8List bytes) async {
    final uuid = Uuid.unparse(bytes.buffer.asUint8List(0, 16));

    final download = downloads[uuid];
    if (download == null) {
      client.send(
        PtpAssetBlobError(
          uuid: uuid,
          error: .operationNotStarted,
        ),
      );
      return;
    }

    await download.addChunk(bytes.buffer.asUint8List(16));
  }

  Future<void> _endDownloadOp(UUID uuid) async {
    final download = downloads.remove(uuid);
    if (download == null) {
      client.send(
        PtpAssetBlobError(
          uuid: uuid,
          error: .operationNotStarted,
        ),
      );
      return;
    }

    await download.finish();

    final db = await _getDatabase();
    await _dbStore.record(uuid).put(db, {
      'uuid': uuid,
      'isBlobLocal': true,
    }, merge: true);

    _locked.remove(uuid);
  }

  Future<void> _onUploadProgress(UUID uuid, int bytesReceived) async {}
}
