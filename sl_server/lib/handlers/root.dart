import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:sl_server/handlers/editor.dart';
import 'package:sl_server/handlers/rooms.dart';
import 'package:sl_server/handlers/thumbs.dart';

Router getRootRouter(bool serveStaticEditor) {
  final router = Router()
    ..get('/', _rootHandler)
    ..mount('/rooms', roomsRouter.call)
    ..mount('/thumbs', thumbRouter.call);

  if (serveStaticEditor) {
    router.mount('/editor', editorHandler);
  }

  return router;
}

final _redirectToEditor = bool.fromEnvironment('dart.vm.product');
Response _rootHandler(Request req) {
  if (_redirectToEditor) {
    return Response.movedPermanently('/editor');
  }
  return Response.ok('Operational.');
}
