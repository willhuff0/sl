import 'dart:io';

import 'package:shelf/shelf.dart' hide Server;
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:sl_server/server.dart';

final Map<String, Server> _rooms = {};

final _router = Router()
  ..get('/', _rootHandler)
  ..get('/joinRoom', _joinRoomHandler)
  ..get('/thumb', _getThumbHandler)
  ..post('/thumb', _postThumbHandler);

Response _rootHandler(Request req) {
  return Response.ok('Hello, World!\n');
}

Response _joinRoomHandler(Request req) {
  final roomId = req.url.queryParameters['room'];
  if (roomId == null) return Response.badRequest(body: 'Query parameter \'room\' must not be null!');
  final room = _rooms[roomId];
  if (room == null) return Response.notFound('Room not found!');
  return room.getWebSocketHandler().handle(req);
}

Future<Response> _getThumbHandler(Request req) async {
  final roomId = req.url.queryParameters['room'];
  if (roomId == null) return Response.badRequest(body: 'Query parameter \'room\' must not be null!');
  final room = _rooms[roomId];
  if (room == null) return Response.notFound('Room not found!');
  return await room.handleGetThumb(req);
}

Future<Response> _postThumbHandler(Request req) async {
  final roomId = req.url.queryParameters['room'];
  if (roomId == null) return Response.badRequest(body: 'Query parameter \'room\' must not be null!');
  final room = _rooms[roomId];
  if (room == null) return Response.notFound('Room not found!');
  return await room.handlePostThumb(req);
}

void main(List<String> args) async {
  try {
    _rooms['test-room'] = await Server.create('test-room');

    final ip = InternetAddress.anyIPv4;

    final handler = Pipeline().addMiddleware(logRequests()).addHandler(_router.call);

    final port = int.parse(Platform.environment['PORT'] ?? '8080');
    final server = await serve(handler, ip, port);

    print('Server listening on port ${server.port}');

    await for (final _ in stdin) {}
  } finally {
    for (final room in _rooms.values) {
      await room.dispose();
    }
  }
}
