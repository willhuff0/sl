import 'dart:io';

import 'package:shelf/shelf.dart' as shelf;
import 'package:sl_server/server.dart';
import 'package:sl_shared/sl_shared.dart';

class AssetThumbs {
  final Server _server;

  AssetThumbs({
    required Server server,
  }) : _server = server;

  Future<shelf.Response> handleGetThumb(shelf.Request req) async {
    final uuid = req.url.queryParameters['uuid'];
    if (uuid == null) return shelf.Response.badRequest(body: 'Query parameter \'uuid\' must not be null!');

    final file = File(_server.pathProvider.getAssetThumbPath(uuid));
    if (!await file.exists()) return shelf.Response.notFound('Asset does not exist or does not have a thumbnail.');
    return shelf.Response.ok(
      file.openRead(),
      headers: {
        'Content-Type': 'image/*',
        'Access-Control-Allow-Origin': '*',
      },
    );
  }

  Future<shelf.Response> handlePostThumb(shelf.Request req) async {
    final uuid = req.url.queryParameters['uuid'];
    if (uuid == null) return shelf.Response.badRequest(body: 'Query parameter \'uuid\' must not be null!');

    final file = File(_server.pathProvider.getAssetThumbPath(uuid));
    await file.create(recursive: true);
    final sink = file.openWrite();
    try {
      await sink.addStream(req.read());
    } finally {
      await sink.close();
    }

    return shelf.Response.ok(
      null,
      headers: {
        'Access-Control-Allow-Origin': '*',
      },
    );
  }

  Future<bool> deleteAssetThumb(Client client, UUID uuid) async {
    final file = File(_server.pathProvider.getAssetThumbPath(uuid));
    if (!await file.exists()) return true;
    await file.delete();
    return true;
  }
}
