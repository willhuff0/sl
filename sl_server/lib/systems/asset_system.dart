import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:sl_shared/src/database/database.dart';
import 'package:sl_server/objects/asset.dart';
import 'package:sl_server/server.dart';
import 'package:sl_server/state_tracker.dart';
import 'package:sl_shared/sl_shared.dart';

class _UploadOperation {
  final UUID uuid;
  final int offset;
  final int length;
  final int size;

  final void Function() onTimeout;
  late Timer _timeoutTimer;
  final RandomAccessFile _file;

  _UploadOperation({
    required this.uuid,
    required this.offset,
    required this.length,
    required this.size,
    required this.onTimeout,
    required RandomAccessFile file,
  }) : _file = file {
    _timeoutTimer = Timer(assetBlobTimeout, _onTimeout);
  }
  static Future<_UploadOperation> openFile({
    required UUID uuid,
    required int offset,
    required int length,
    required int size,
    required void Function() onTimeout,
    required String path,
  }) async {
    final file = await File(path).open(mode: .writeOnlyAppend);
    await file.truncate(size);
    await file.setPosition(offset);
    return _UploadOperation(
      uuid: uuid,
      offset: offset,
      length: length,
      size: size,
      onTimeout: onTimeout,
      file: file,
    );
  }

  var _bytesReceived = 0;
  var _progressIntervalCounter = 0;

  Future<StcAssetBlobProgress?> addChunk(Uint8List chunk) async {
    _timeoutTimer.cancel();
    _timeoutTimer = Timer(assetBlobTimeout, _onTimeout);

    _bytesReceived += chunk.length;
    if (_bytesReceived > length) {
      // TODO: check size
    }
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
  final Database database;

  late final StateTracker _stateTracker;

  final Map<Client, UUID?> _clientToSubscribedDirectories = {};
  final Map<UUID?, Set<Client>> _directoryToSubscribedClients = {};

  final Map<Client, _UploadOperation> _uploads = {};
  final Set<UUID> _locked = {};

  AssetSystem(this.server, this.database) {
    _stateTracker = StateTracker(
      server,
      StateTrackerSystem.asset,
      getInterestedClients: _getInterestedClients,
      loadObjectFromDisk: _loadObjectFromDisk,
    );
  }

  String _getPathOfAssetBlob(UUID uuid) {
    return p.join(server.rootPath, 'blobs', uuid);
  }

  Future<void> removeClient(Client client) async {
    _removeClientListenDirectory(client);
    await _clientAbandonUpload(client);
  }

  String? _encodeAssetProperties(dynamic properties) {
    if (properties == null) return null;
    return jsonEncode(properties);
  }

  Future<void> handleClientChanges(Client client, CtsStateChanges stateChanges) async {
    await database.batch((b) async {
      await _stateTracker.handleClientChanges(
        client,
        stateChanges,
        insertBuilder: (tracked) {
          tracked = tracked as TrackedAsset;
          b.insert(
            database.assets,
            AssetsCompanion.insert(
              uuid: tracked.uuid,
              parent: Value.absentIfNull(tracked.parent.value),
              name: tracked.name.value,
              type: tracked.type.value,
              properties: Value.absentIfNull(_encodeAssetProperties(tracked.properties.value)),
              blobSize: Value.absentIfNull(tracked.blobSize.value),
            ),
          );
        },
        updateBuilder: (change, tracked) {
          tracked = tracked as TrackedAsset;
          b.update(
            database.assets,
            AssetsCompanion(
              parent: change.containsKey(tracked.parent.key) ? Value(tracked.parent.value) : Value.absent(),
              name: change.containsKey(tracked.name.key) ? Value(tracked.name.value) : Value.absent(),
              type: change.containsKey(tracked.type.key) ? Value(tracked.type.value) : Value.absent(),
              properties: change.containsKey(tracked.properties.key)
                  ? Value(_encodeAssetProperties(tracked.properties.value))
                  : Value.absent(),
              blobSize: change.containsKey(tracked.blobSize.key) ? Value(tracked.blobSize.value) : Value.absent(),
            ),
            where: (a) => a.uuid.equals(tracked.uuid),
          );
        },
      );
    });
  }

  Future<bool> handleMessage(Client client, Message message) async {
    switch (message) {
      case CtsListenToAssetDirectory listenToAssetDirectory:
        _setClientListenDirectory(client, listenToAssetDirectory.directory);
        break;
      case PtpAssetBlobStart startOp:
        await _startUploadOp(client, startOp.uuid, startOp.offset, startOp.length, startOp.size);
        break;
      case PtpAssetBlobEnd endOp:
        await _endUploadOp(client, endOp.uuid);
        break;
      default:
        return false;
    }
    return true;
  }

  Set<Client> _getInterestedClients(UUID? scope, UUID uuid) {
    return _directoryToSubscribedClients[scope] ?? {};

    // var tracked = _stateTracker.getObjectInMemory(uuid) as TrackedAsset?;
    // while (tracked != null && tracked.type.value != .directory) {
    //   final parent = tracked.parent.value;
    //   if (parent == null) throw Exception('Asset tree is disconnected.');
    //   tracked = _stateTracker.getObjectInMemory(parent) as TrackedAsset?;
    // }
    // return _directoryToSubscribedClients[tracked?.uuid] ?? {};
  }

  Future<StateTracked?> _loadObjectFromDisk(UUID uuid) async {
    final asset = await database.getAssetByUUID(uuid).getSingleOrNull();
    if (asset == null) return null;
    return TrackedAsset.fromDatabase(_stateTracker, asset, false);
  }

  Future<void> _startUploadOp(Client client, UUID uuid, int offset, int length, int size) async {
    if (_uploads.containsKey(client)) {
      server.send(
        client,
        PtpAssetBlobError(
          uuid: null,
          error: .simultaneousUploadsFromSingleClientNotAllowed,
        ),
      );
      return;
    }
    if (_locked.contains(uuid)) {
      server.send(
        client,
        PtpAssetBlobError(
          uuid: uuid,
          error: .assetBlobLocked,
        ),
      );
      return;
    }
    _locked.add(uuid);

    _uploads[client] = await _UploadOperation.openFile(
      uuid: uuid,
      offset: offset,
      length: length,
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
          error: .operationNotStarted,
        ),
      );
      return;
    }

    final progressUpdate = await upload.addChunk(bytes);
    if (progressUpdate != null) {
      server.send(client, progressUpdate);
    }
  }

  Future<void> _endUploadOp(Client client, UUID uuid) async {
    final upload = _uploads.remove(client);
    if (upload == null) {
      server.send(
        client,
        PtpAssetBlobError(
          uuid: uuid,
          error: .operationNotStarted,
        ),
      );
      return;
    }

    await upload.finish();
    _locked.remove(upload.uuid);
  }

  void _onUploadTimeout(Client client) {
    final upload = _uploads.remove(client);
    if (upload != null) {
      _locked.remove(upload.uuid);
      server.send(
        client,
        PtpAssetBlobError(
          uuid: upload.uuid,
          error: .operationTimedOut,
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

  void _setClientListenDirectory(Client client, UUID? directory) {
    if (_clientToSubscribedDirectories.containsKey(client)) {
      if (directory != _clientToSubscribedDirectories[client]) {
        _removeClientListenDirectory(client);
      }
    }

    if (directory != _clientToSubscribedDirectories[client]) {}

    final current = _clientToSubscribedDirectories[client];
    if (current != null) {
      final subscribedClientsToCurrent = _directoryToSubscribedClients[current]!;
      subscribedClientsToCurrent.remove(client);
      if (subscribedClientsToCurrent.isEmpty) {
        _directoryToSubscribedClients.remove(current);
      }
    }

    _clientToSubscribedDirectories[client] = directory;
    final subscribedClients = _directoryToSubscribedClients[directory] ??= {};
    subscribedClients.add(client);

    // await _sendEntireDirectory(client, directory);
    _loadAndSendEntireDirectory(client, directory);
  }

  void _removeClientListenDirectory(Client client) {
    if (!_clientToSubscribedDirectories.containsKey(client)) return;

    final directory = _clientToSubscribedDirectories.remove(client);
    final subscribedClients = _directoryToSubscribedClients[directory]!;
    subscribedClients.remove(client);

    if (subscribedClients.isEmpty) _directoryToSubscribedClients.remove(directory);
  }

  Future<void> _loadAndSendEntireDirectory(Client client, UUID? directory) async {
    final rows = await database.getAssetsInDirectory(directory).get();
    _stateTracker.preloadObjectsForClient(
      client,
      directory,
      rows
          .where((row) => !_stateTracker.isObjectLoaded(row.uuid))
          .map(
            (row) => TrackedAsset.fromDatabase(
              _stateTracker,
              Asset(
                uuid: row.uuid,
                parent: row.parent,
                name: row.name,
                type: row.type,
                properties: row.properties,
                blobSize: row.blobSize,
              ),
              false,
            ),
          ),
    );
  }
}
