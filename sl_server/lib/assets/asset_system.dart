import 'dart:async';
import 'dart:typed_data';

import 'package:shelf/shelf.dart' as shelf;
import 'package:sl_server/assets/asset_blob_transferer.dart';
import 'package:sl_server/assets/asset_thumbs.dart';
import 'package:sl_server/client.dart';
import 'package:sl_server/server.dart';
import 'package:sl_shared/sl_shared.dart';
import 'package:sqlite_crdt/sqlite_crdt.dart';

class AssetSystem {
  final Server _server;
  final SqliteCrdt _sharedDatabase;
  final AssetBlobTransferer _blobTransferer;
  final AssetThumbs _thumbs;

  final Map<Client, CrdtSync> _clientToCrdtSync = {};

  AssetSystem(
    this._server,
    this._sharedDatabase,
  ) : _blobTransferer = AssetBlobTransferer(
        server: _server,
        sharedDatabase: _sharedDatabase,
      ),
      _thumbs = AssetThumbs(
        server: _server,
      );

  Future<void> addClient(Client client) async {
    _clientToCrdtSync[client] = CrdtSync.server(
      _sharedDatabase,
      send: (message) => _server.send(
        client,
        PtpCrdtSync(
          message: message,
        ),
      ),
      verbose: false,
    );
  }

  Future<void> removeClient(Client client) async {
    _clientToCrdtSync.remove(client)?.syncSocket.close();
    await _blobTransferer.cancelClientUploads(client);
  }

  Future<bool> handleMessage(Client client, Message message) async {
    switch (message) {
      case PtpCrdtSync crdtSync:
        _clientToCrdtSync[client]!.syncSocket.receive(crdtSync.message);
        break;
      case CtsRequestAssetBlob request:
        await _blobTransferer.download(client, request.uuid, request.offset);
        break;
      case PtpAssetBlobStart startOp:
        await _blobTransferer.handleStartUpload(client, startOp.uuid, startOp.offset, startOp.size);
        break;
      case PtpAssetBlobEnd endOp:
        await _blobTransferer.handleEndUpload(client, endOp.uuid, endOp.version);
        break;
      case CtsDeleteAssets deleteAssets:
        await _deleteAssets(client, deleteAssets.uuids);
        break;
      default:
        return false;
    }
    return true;
  }

  Future<void> handleBinary(Client client, Uint8List bytes) async {
    await _blobTransferer.handleBinary(client, bytes);
  }

  Future<shelf.Response> handleGetThumb(shelf.Request req) {
    return _thumbs.handleGetThumb(req);
  }

  Future<shelf.Response> handlePostThumb(shelf.Request req) {
    return _thumbs.handlePostThumb(req);
  }

  Future<void> _deleteAssets(Client client, Set<UUID> uuids) async {
    // TODO: in between deleting blobs and deleting rows, client could try to pull asset blob
    // TODO: does not recurse beyond one level deep of subassets

    final toDelete = <UUID>[];
    await Future.wait(
      uuids.map((uuid) async {
        final blobDeletedSuccessfully = await _blobTransferer.deleteAssetBlob(client, uuid);
        if (!blobDeletedSuccessfully) return;
        toDelete.add(uuid);
      }),
    );
    await _sharedDatabase.execute('''
DELETE FROM assets WHERE (
  uuid IN (${List.generate(toDelete.length, (i) => '?${i + 1}').join(',')}) OR
  parent IN (${List.generate(toDelete.length, (i) => '?${i + 1}').join(',')})
) AND is_deleted = 0;
''', toDelete);
  }
}
