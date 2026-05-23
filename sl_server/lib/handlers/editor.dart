import 'package:shelf_static/shelf_static.dart';
import 'package:sl_server/globals.dart';

final editorHandler = createStaticHandler(ServerGlobalConstants.editorPublicDir, defaultDocument: 'index.html');
