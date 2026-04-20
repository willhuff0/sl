import 'dart:async';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:sl_editor/client/client.dart';
import 'package:sl_shared/sl_shared.dart';

class AssetThumbs {
  static final _mimeCache = <UUID, String?>{};
  static String? getCachedMime(UUID uuid) {
    return _mimeCache[uuid];
  }

  static FutureOr<String?> getMime(UUID uuid) async {
    var cache = _mimeCache[uuid];
    if (cache != null) return cache;

    final database = Client.get().assetSystem.sharedDatabase;
    final rows = await database.query('SELECT thumb_mime FROM assets WHERE uuid = ?1 AND is_deleted = 0;', [uuid]);
    if (rows.isEmpty) return null;
    return _mimeCache[uuid] = rows.first['thumb_mime'] as String?;
  }

  static String getUri(UUID uuid) {
    return Client.get().serverUri
        .replace(
          path: 'thumb',
          queryParameters: {
            'room': Client.get().projectId,
            'uuid': uuid,
          },
        )
        .toString();
  }

  static Future<void> upload(UUID uuid, Uint8List bytes) async {
    await http.post(
      Client.get().serverUri.replace(
        path: 'thumb',
        queryParameters: {
          'room': Client.get().projectId,
          'uuid': uuid,
        },
      ),
      body: bytes,
    );
  }
}
