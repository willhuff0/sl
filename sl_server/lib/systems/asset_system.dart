import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:sl_server/server.dart';
import 'package:sl_shared/sl_shared.dart';
import 'package:sqlite_crdt/sqlite_crdt.dart';
import 'package:uuid/uuid.dart';

class _UploadOperation {
  final UUID uuid;
  final int offset;
  final int size;

  final void Function() onTimeout;
  late Timer _timeoutTimer;
  final RandomAccessFile _file;

  _UploadOperation({
    required this.uuid,
    required this.offset,
    required this.size,
    required this.onTimeout,
    required RandomAccessFile file,
  }) : _file = file {
    _timeoutTimer = Timer(assetBlobTimeout, _onTimeout);
  }
  static Future<_UploadOperation> openFile({
    required UUID uuid,
    required int offset,
    required int size,
    required void Function() onTimeout,
    required String path,
  }) async {
    final file = File(path);
    await file.create(recursive: true);
    final writer = await file.open(mode: .writeOnlyAppend);
    await writer.truncate(size);
    await writer.setPosition(offset);
    return _UploadOperation(
      uuid: uuid,
      offset: offset,
      size: size,
      onTimeout: onTimeout,
      file: writer,
    );
  }

  var _bytesReceived = 0;
  var _progressIntervalCounter = 0;

  Future<StcAssetBlobProgress?> addChunk(Uint8List chunk) async {
    _timeoutTimer.cancel();
    _timeoutTimer = Timer(assetBlobTimeout, _onTimeout);

    _bytesReceived += chunk.length;
    await _file.writeFrom(chunk);

    _progressIntervalCounter = (_progressIntervalCounter + 1) % assetBlobProgressInterval;
    if (_progressIntervalCounter == 0) {
      return StcAssetBlobProgress(
        uuid: uuid,
        bytesReceived: _bytesReceived,
      );
    } else {
      return null;
    }
  }

  Future<void> finish() async {
    _timeoutTimer.cancel();
    await _file.close();
  }

  void _onTimeout() {
    _timeoutTimer.cancel();
    _file.closeSync();
    onTimeout();
  }
}

class AssetSystem {
  final Server server;
  final SqliteCrdt _database;

  final Map<Client, CrdtSync> _clientToCrdtSync = {};

  final Map<Client, _UploadOperation> _uploads = {};
  final Set<UUID> _locked = {};

  AssetSystem(this.server, this._database);

  String _getPathOfAssetBlob(UUID uuid) {
    return p.join(server.rootPath, 'blobs', uuid);
  }

  Future<void> addClient(Client client) async {
    _clientToCrdtSync[client] = CrdtSync.server(
      _database,
      send: (message) => server.send(client, PtpCrdtSync(message: message)),
      verbose: true,
    );
  }

  Future<void> removeClient(Client client) async {
    _clientToCrdtSync.remove(client);
    await _clientAbandonUpload(client);
  }

  Future<bool> handleMessage(Client client, Message message) async {
    switch (message) {
      case PtpCrdtSync crdtSync:
        _clientToCrdtSync[client]!.syncSocket.receive(crdtSync.message);
        break;
      case CtsRequestAssetBlob request:
        await _sendAssetBlobToClient(client, request.uuid, request.offset);
        break;
      case PtpAssetBlobStart startOp:
        await _startUploadOp(client, startOp.uuid, startOp.offset, startOp.size);
        break;
      case PtpAssetBlobEnd endOp:
        await _endUploadOp(client, endOp.uuid);
        break;
      default:
        return false;
    }
    return true;
  }

  // Future<void> _downloadToClient(Client client, UUID uuid, int offset) async {

  // }

  Future<void> _startUploadOp(Client client, UUID uuid, int offset, int size) async {
    if (_uploads.containsKey(client)) {
      server.send(
        client,
        PtpAssetBlobError(
          uuid: null,
          error: 'simultaneousUploadsFromSingleClientNotAllowed',
        ),
      );
      return;
    }
    if (_locked.contains(uuid)) {
      server.send(
        client,
        PtpAssetBlobError(
          uuid: uuid,
          error: 'assetBlobLocked',
        ),
      );
      return;
    }
    _locked.add(uuid);

    _uploads[client] = await _UploadOperation.openFile(
      uuid: uuid,
      offset: offset,
      size: size,
      onTimeout: () => _onUploadTimeout(client),
      path: _getPathOfAssetBlob(uuid),
    );
  }

  Future<void> handleBinary(Client client, Uint8List bytes) async {
    final upload = _uploads[client];
    if (upload == null) {
      server.send(
        client,
        PtpAssetBlobError(
          uuid: null,
          error: 'operationNotStarted',
        ),
      );
      return;
    }

    final progressUpdate = await upload.addChunk(bytes.sublist(16));
    if (progressUpdate != null) {
      server.send(client, progressUpdate);

      await _database.execute(
        'UPDATE assets SET blob_upload_progress = ?1 WHERE uuid = ?2;',
        [progressUpdate.bytesReceived, upload.uuid],
      );
    }
  }

  Future<void> _endUploadOp(Client client, UUID uuid) async {
    final upload = _uploads.remove(client);
    if (upload == null) {
      server.send(
        client,
        PtpAssetBlobError(
          uuid: uuid,
          error: 'operationNotStarted',
        ),
      );
      return;
    }

    await upload.finish();
    _locked.remove(upload.uuid);

    final blobUpdatedAt = DateTime.now().toIso8601String();
    await _database.execute(
      'UPDATE assets SET blob_size = ?1, blob_updated_at = ?2, blob_upload_progress = ?3 WHERE uuid = ?4;',
      [upload.size, blobUpdatedAt, null, uuid],
    );
  }

  void _onUploadTimeout(Client client) {
    final upload = _uploads.remove(client);
    if (upload != null) {
      _locked.remove(upload.uuid);
      server.send(
        client,
        PtpAssetBlobError(
          uuid: upload.uuid,
          error: 'operationTimedOut',
        ),
      );
    }
  }

  Future<void> _clientAbandonUpload(Client client) async {
    final upload = _uploads.remove(client);
    if (upload != null) {
      await upload.finish();
      _locked.remove(upload.uuid);
    }
  }

  Future<void> _sendAssetBlobToClient(Client client, UUID uuid, int offset) async {
    if (_locked.contains(uuid)) {
      // TODO: error
      return;
    }
    _locked.add(uuid);

    try {
      final file = File(_getPathOfAssetBlob(uuid));
      if (!await file.exists()) {
        print('client requested an asset blob which doesn\'t exist');
        return;
      }

      final fileSize = await file.length();

      server.send(
        client,
        PtpAssetBlobStart(
          uuid: uuid,
          offset: offset,
          size: fileSize,
        ),
      );

      final reader = await file.open();
      await reader.setPosition(offset);

      final buffer = Uint8List(assetBlobChunkSize + 16); // prepended with uuid
      Uuid.parse(uuid, buffer: buffer);
      var bytesRemaining = fileSize;
      while (bytesRemaining > 0) {
        final chunkSize = await reader.readInto(buffer, 16, min(assetBlobChunkSize, bytesRemaining) + 16);
        if (chunkSize == 0) break;

        server.sendBinary(client, buffer.buffer.asUint8List(0, chunkSize + 16));
        bytesRemaining -= chunkSize;
      }
    } finally {
      _locked.remove(uuid);

      server.send(
        client,
        PtpAssetBlobEnd(
          uuid: uuid,
        ),
      );
    }
  }
}
