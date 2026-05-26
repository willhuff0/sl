import 'package:path/path.dart' as p;
import 'package:sl_server/server.dart';

class ServerGlobalConstants {
  static const serverRoot = 'root';
  static final editorPublicDir = p.join(serverRoot, 'public');
}

class ServerGlobalState {
  static final Map<String, Server> _rooms = {};
  static final Map<String, Future> _disposeFutures = {};

  static Server? getRoom(String projectId) {
    return _rooms[projectId];
  }

  static Future<Server> openRoom(String projectId, {bool allowMutation = true}) async {
    var room = _rooms[projectId];
    if (room != null) return room;

    await _disposeFutures[projectId];

    final constructor = allowMutation ? Server.openProject : Server.openProjectNoMutate;
    return _rooms[projectId] = await constructor(projectId, p.join(ServerGlobalConstants.serverRoot, projectId));
  }

  static Future<void> closeRoom(String projectId) async {
    final room = _rooms.remove(projectId);
    if (room == null) return;
    await (_disposeFutures[projectId] = room.dispose().then((_) => _disposeFutures.remove(projectId)));
  }

  static Future<void> dispose() async {
    for (final room in _rooms.values) {
      await _disposeFutures[room.projectId];
      await room.dispose();
    }
  }
}
