import 'package:path/path.dart' as p;
import 'package:sl_server/server.dart';

class ServerGlobalConstants {
  static const serverRoot = 'root';
  static final editorPublicDir = p.join(serverRoot, 'public');
}

class ServerGlobalState {
  static Map<String, Server> rooms = {};

  static Future<void> dispose() async {
    for (final room in rooms.values) {
      await room.dispose();
    }
  }
}
