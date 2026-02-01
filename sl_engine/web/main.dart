import 'package:sl_engine/sl_engine.dart';
import 'package:web/web.dart' as web;

void main() {
  final canvas = web.document.querySelector('#sl-engine-canvas') as web.HTMLCanvasElement?;
  if (canvas == null) throw Exception('Failed to find sl engine canvas!');
  initialize(canvas);
}
