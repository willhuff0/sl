import 'dart:io';

import 'package:shelf/shelf.dart' hide Server;
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:sl_server/server.dart';

final Map<String, Server> _rooms = {
  'test-room': Server('test-room'),
};

final _router = Router()
  ..get('/', _rootHandler)
  ..get('/joinRoom', _joinRoomHandler);

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

void main(List<String> args) async {
  final ip = InternetAddress.anyIPv4;

  final handler = Pipeline().addMiddleware(logRequests()).addHandler(_router.call);

  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);

  print('Server listening on port ${server.port}');
}
