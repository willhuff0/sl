import 'package:sl_engine/editor/sl_editor.dart';
import 'package:web/web.dart' as web;

void main() {
  final canvas = web.document.querySelector('#sl-engine-canvas') as web.HTMLCanvasElement?;
  if (canvas == null) throw Exception('Failed to find sl-engine-canvas!');
  SLEditor.initSlEditorMode(canvas);
}
