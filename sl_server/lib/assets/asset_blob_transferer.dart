import 'dart:io';
import 'dart:typed_data';

import 'package:sl_server/client.dart';
import 'package:sl_server/server.dart';
import 'package:sl_shared/sl_shared.dart';
import 'package:sqlite_crdt/sqlite_crdt.dart';
import 'package:uuid/uuid.dart';

class _UploadOperation {
  final Client client;
  final UUID uuid;
  final int offset;
  final int size;
  final String path;

  _UploadOperation({
    required this.client,
    required this.uuid,
    required this.offset,
    required this.size,
    required this.path,
  });

  late final File _stagingFile;
  late final RandomAccessFile _stagingWriter;

  var _bytesReceived = 0;
  var _progressIntervalCounter = 0;

  Future<void> start() async {
    _stagingFile = File('$path.upload');
    await _stagingFile.create(recursive: true);

    _stagingWriter = await _stagingFile.open(mode: .write);
    await _stagingWriter.truncate(size - offset);
    await _stagingWriter.setPosition(0);
  }

  Future<StcAssetBlobProgress?> addChunk(Uint8List chunk) async {
    _bytesReceived += chunk.length;
    await _stagingWriter.writeFrom(chunk, 0, chunk.length);

    _progressIntervalCounter = (_progressIntervalCounter + 1) % assetBlobProgressInterval;
    if (_progressIntervalCounter == 0 || (_bytesReceived >= size - offset)) {
      return StcAssetBlobProgress(
        uuid: uuid,
        bytesReceived: _bytesReceived,
      );
    } else {
      return null;
    }
  }

  Future<void> finish() async {
    RandomAccessFile? writer;
    try {
      await _stagingWriter.setPosition(0);

      final file = File(path);
      if (await file.exists()) {
        // merge staging with existing file

        writer = await file.open(mode: .writeOnlyAppend);
        await writer.truncate(size);
        await writer.setPosition(offset);

        const bufferSize = 1024 * 64;
        final buffer = Uint8List(bufferSize);

        final fileLength = size - offset;
        var bytesRead = 0;

        while (bytesRead < fileLength) {
          final actualBytesRead = await _stagingWriter.readInto(buffer);
          await writer.writeFrom(buffer, 0, actualBytesRead);
          bytesRead += actualBytesRead;
        }

        await _stagingWriter.close();
        await writer.close();
        await _stagingFile.delete();
      } else {
        // make staging file permanent

        await _stagingWriter.close();
        await _stagingFile.rename(path);
      }
    } catch (_) {
      await _stagingWriter.close();
      await writer?.close();
      await _stagingFile.delete();
    }
  }

  Future<void> cancel() async {
    await _stagingWriter.close();
    await _stagingFile.delete();
  }
}

class AssetBlobTransferer {
  final Server _server;
  final SqliteCrdt _sharedDatabase;

  final _uploads = <UUID, _UploadOperation>{};
  final _clientToUploads = <Client, Set<UUID>>{};
  final _downloads = <UUID, int>{};

  AssetBlobTransferer({
    required Server server,
    required SqliteCrdt sharedDatabase,
  }) : _server = server,
       _sharedDatabase = sharedDatabase;

  void _sendError(Client client, UUID? uuid, String error) {
    _server.send(
      client,
      PtpAssetBlobError(
        uuid: uuid,
        error: error,
      ),
    );
  }

  Future<void> download(Client client, UUID uuid, int offset) async {
    if (_uploads.containsKey(uuid)) {
      _sendError(
        client,
        uuid,
        'Tried to start a download of the blob for asset $uuid while it was still uploading.',
      );
      return;
    }

    final downloadCount = _downloads[uuid] ?? 0;
    _downloads[uuid] = downloadCount + 1;
    try {
      final rows = await _sharedDatabase.query(
        'SELECT blob_size, blob_version FROM assets WHERE uuid = ?1 AND is_deleted = 0',
        [uuid],
      );
      if (rows.isEmpty) {
        _sendError(
          client,
          uuid,
          'Tried to start a download of the blob for asset $uuid, which does not exist.',
        );
        return;
      }
      final size = rows.first['blob_size'] as int?;
      if (size == null) {
        _sendError(
          client,
          uuid,
          'Tried to start a download of the blob for asset $uuid which does not have a blob (size).',
        );
        return;
      }
      final version = rows.first['blob_version'] as int?;
      if (version == null) {
        _sendError(
          client,
          uuid,
          'Tried to start a download of the blob for asset $uuid which does not have a blob (version number).',
        );
        return;
      }

      if (offset >= size) {
        _sendError(
          client,
          uuid,
          'Tried to start a download of the blob for asset $uuid at offset $offset bytes but the blob_size is only $size bytes.',
        );
        return;
      }

      final file = File(_server.pathProvider.getAssetBlobPath(uuid));
      if (!await file.exists()) {
        _sendError(
          client,
          uuid,
          'Tried to start a download of the blob for asset $uuid which has blob_size $size bytes but the file does not exist.',
        );
        return;
      }
      {
        final fileLength = await file.length();
        if (fileLength != size) {
          _sendError(
            client,
            uuid,
            'Tried to start a download of the blob for asset $uuid which has blob_size $size bytes but the file has size $fileLength bytes.',
          );
          return;
        }
      }

      final reader = await file.open();
      try {
        await reader.setPosition(offset);

        _server.send(
          client,
          PtpAssetBlobStart(
            uuid: uuid,
            offset: offset,
            size: size,
          ),
        );
        try {
          var bytesRead = 0;
          while (bytesRead < size - offset) {
            // recreate every time to avoid websocket queue related problems
            final buffer = Uint8List(assetBlobChunkSize + 16);
            Uuid.parse(uuid, buffer: buffer);

            final actualBytesRead = await reader.readInto(buffer, 16);
            _server.sendBinary(client, Uint8List.sublistView(buffer, 0, actualBytesRead + 16));
            bytesRead += actualBytesRead;
          }
        } finally {
          _server.send(
            client,
            PtpAssetBlobEnd(
              uuid: uuid,
              version: version,
            ),
          );
        }
      } finally {
        await reader.close();
      }
    } finally {
      final downloadCount = _downloads[uuid] ?? 0;
      if (downloadCount > 1) {
        _downloads[uuid] = downloadCount - 1;
      } else {
        _downloads.remove(uuid);
      }
    }
  }

  Future<void> handleStartUpload(Client client, UUID uuid, int offset, int size) async {
    try {
      if (_uploads.containsKey(uuid)) {
        _sendError(
          client,
          uuid,
          'Client initiated an upload of the blob for asset $uuid while an upload for the blob was already in progress.',
        );
        return;
      }
      if (_downloads.containsKey(uuid)) {
        _sendError(
          client,
          uuid,
          'Client initiated an upload of the blob for asset $uuid while a download for the blob was in progress.',
        );
        return;
      }

      final clientUploads = _clientToUploads[client] ??= {};
      clientUploads.add(uuid);

      final upload = _uploads[uuid] = _UploadOperation(
        client: client,
        uuid: uuid,
        offset: offset,
        size: size,
        path: _server.pathProvider.getAssetBlobPath(uuid),
      );
      await upload.start();
    } catch (_) {
      await _uploads[uuid]?.cancel();
      _uploads.remove(uuid);
      _clientToUploads[client]?.remove(uuid);
    }
  }

  Future<void> handleBinary(Client client, Uint8List bytes) async {
    final uuid = Uuid.unparse(Uint8List.sublistView(bytes, 0, 16));

    final upload = _uploads[uuid];
    if (upload == null) {
      _sendError(
        client,
        uuid,
        'Client sent a chunk of the blob for asset $uuid while an upload was not in progress.',
      );
      return;
    }
    if (upload.client != client) {
      _sendError(
        client,
        uuid,
        'Client sent a chunk of the blob for asset $uuid without being associated with the upload operation.',
      );
      return;
    }

    final progressUpdate = await upload.addChunk(Uint8List.sublistView(bytes, 16));
    if (progressUpdate != null) {
      _server.send(client, progressUpdate);
    }
  }

  Future<void> handleEndUpload(Client client, UUID uuid, int version) async {
    try {
      final upload = _uploads[uuid];
      if (upload == null) {
        _sendError(
          client,
          uuid,
          'Client finalized an upload of the blob for asset $uuid while an upload was not in progress.',
        );
        return;
      }

      await upload.finish();

      await _sharedDatabase.execute(
        'UPDATE assets SET blob_size = ?1, blob_version = ?2 WHERE uuid = ?3;',
        [upload.size, version, uuid],
      );
    } finally {
      _uploads.remove(uuid);
      _clientToUploads[client]?.remove(uuid);
    }
  }

  Future<void> cancelClientUploads(Client client) async {
    for (final uuid in _clientToUploads[client] ?? <UUID>{}) {
      await _uploads[uuid]?.cancel();
      _uploads.remove(uuid);
    }
    _clientToUploads.remove(client);
  }

  Future<bool> deleteAssetBlob(Client client, UUID uuid) async {
    if (_uploads.containsKey(uuid) || _downloads.containsKey(uuid)) {
      _sendError(client, uuid, 'Cannot delete an asset while an upload or download for its blob is in progress.');
      return false;
    }

    final file = File(_server.pathProvider.getAssetBlobPath(uuid));
    if (!await file.exists()) return true;
    await file.delete();
    return true;
  }
}
