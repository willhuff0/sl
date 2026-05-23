import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:sl_server/globals.dart';

final roomsRouter = Router()..get('/join', _joinHandler);

Response _joinHandler(Request req) {
  final projectId = req.url.queryParameters['project'];
  if (projectId == null) return Response.badRequest(body: 'Query parameter \'project\' must not be null!');
  final room = ServerGlobalState.rooms[projectId];
  if (room == null) return Response.notFound('Project not found!');
  return room.getWebSocketHandler().handle(req);
}
