import 'dart:js_interop';

import 'package:web/web.dart' as web;

typedef Canvas = web.HTMLCanvasElement;
typedef GL = web.WebGL2RenderingContext;

late final Canvas canvas;
late final GL gl;

void initGl(Canvas canvas_) {
  canvas = canvas_;
  final context =
      canvas.getContext(
            'webgl2',
            {
              'powerPreference': 'high-performance',
              'antialias': true,
              'depth': true,
            }.jsify(),
          )
          as web.WebGL2RenderingContext?;
  if (context == null) throw Exception('Failed to get WebGL2 context!');
  gl = context;
}
