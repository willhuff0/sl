import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:sl_server/globals.dart';

final thumbRouter = Router()
  ..get('/', _getHandler)
  ..post('/', _postHandler);

Future<Response> _getHandler(Request req) async {
  final projectId = req.url.queryParameters['project'];
  if (projectId == null) return Response.badRequest(body: 'Query parameter \'project\' must not be null!');
  final room = ServerGlobalState.getRoom(projectId);
  if (room == null) return Response.notFound('Room not found!');
  return await room.handleGetThumb(req);
}

Future<Response> _postHandler(Request req) async {
  final projectId = req.url.queryParameters['project'];
  if (projectId == null) return Response.badRequest(body: 'Query parameter \'project\' must not be null!');
  final room = ServerGlobalState.getRoom(projectId);
  if (room == null) return Response.notFound('Room not found!');
  return await room.handlePostThumb(req);
}
