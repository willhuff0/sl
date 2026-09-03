import 'dart:async';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:sl_editor/client/client.dart';
import 'package:sl_engine/logger.dart';
import 'package:sl_shared/sl_shared.dart';

class AssetThumbs {
  static final _mimeCache = <UUID, String?>{};
  static String? getCachedMime(UUID uuid) {
    return _mimeCache[uuid];
  }

  static FutureOr<String?> getMime(UUID uuid) async {
    var cache = _mimeCache[uuid];
    if (cache != null) return cache;

    final (exists, mime) = await Client.get().assetSystem.sharedDatabase.getAssetThumbMime(uuid);
    if (!exists) return null;
    return _mimeCache[uuid] = mime;
  }

  static String getUri(UUID uuid) {
    final (exists, uri) = Client.get().assetSystem.sharedDatabase.getAssetThumbUri(uuid);
    if (!exists) return '';
    return uri ?? '';
  }

  static Future<void> upload(UUID uuid, Uint8List bytes) async {
    if (Client.get().assetSystem.sharedDatabase.isBuiltinAsset(uuid)) {
      Logger.log('Tried to upload to a built-in asset thumb $uuid', .warning);
      return;
    }

    await http.post(
      Client.get().serverUri.replace(
        path: 'thumbs',
        queryParameters: {
          'project': Client.get().projectId,
          'uuid': uuid,
        },
      ),
      body: bytes,
    );
  }
}
