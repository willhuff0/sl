import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart' hide Server;
import 'package:shelf/shelf_io.dart';
import 'package:sl_server/globals.dart';
import 'package:sl_server/handlers/root.dart';
import 'package:sl_server/server.dart';

void main(List<String> args) async {
  try {
    var serveStaticEditor = bool.fromEnvironment('dart.vm.product');

    ServerGlobalState.rooms['test-room'] = await Server.openProjectNoMutate(
      p.join(ServerGlobalConstants.serverRoot, 'test-room'),
    );

    final ip = InternetAddress.anyIPv4;

    final handler = Pipeline().addMiddleware(logRequests()).addHandler(getRootRouter(serveStaticEditor).call);

    final port = int.parse(Platform.environment['PORT'] ?? '8080');
    final server = await serve(handler, ip, port);

    print('Server listening on port ${server.port}');
    if (serveStaticEditor) print('Hosting client app at ${server.address.address}/editor');

    await for (final _ in stdin) {}
  } finally {
    await ServerGlobalState.dispose();
  }
}
