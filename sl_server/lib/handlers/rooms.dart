import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:sl_server/globals.dart';

final roomsRouter = Router()..get('/join', _joinHandler);

Future<Response> _joinHandler(Request req) async {
  final projectId = req.url.queryParameters['project'];
  if (projectId == null) return Response.badRequest(body: 'Query parameter \'project\' must not be null!');
  var room = ServerGlobalState.getRoom(projectId);
  if (room == null) {
    if (projectId != 'demo') return Response.notFound('Project not found!');
    room = await ServerGlobalState.openRoom('demo', allowMutation: false);
  }
  return room.getWebSocketHandler().handle(req);
}
