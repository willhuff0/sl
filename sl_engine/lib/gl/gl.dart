import 'dart:js_interop';

import 'package:web/web.dart' as web;

typedef Canvas = web.HTMLCanvasElement;
typedef GL = web.WebGL2RenderingContext;

web.WebGLFramebuffer? defaultFramebuffer;

late final Canvas canvas;
late final GL gl;

late final int canvasColorFormat;
late final int canvasColorType;
late final int canvasDepthBits;
late final int canvasSampleCount;

void initGl(Canvas canvas_, {bool vr = false}) {
  canvas = canvas_;
  final context =
      canvas.getContext(
            'webgl2',
            {
              'powerPreference': 'high-performance',
              'antialias': true,
              'depth': true,
              'xrCompatible': vr,
            }.jsify(),
          )
          as web.WebGL2RenderingContext?;
  if (context == null) throw Exception('Failed to get WebGL2 context!');
  gl = context;

  gl.getExtension('EXT_color_buffer_float');

  canvasColorFormat = (gl.getParameter(GL.IMPLEMENTATION_COLOR_READ_FORMAT) as JSNumber).toDartInt;
  canvasColorType = (gl.getParameter(GL.IMPLEMENTATION_COLOR_READ_TYPE) as JSNumber).toDartInt;
  canvasDepthBits = (gl.getParameter(GL.DEPTH_BITS) as JSNumber).toDartInt;
  canvasSampleCount = (gl.getParameter(GL.SAMPLES) as JSNumber).toDartInt;

  gl.enable(GL.DEPTH_TEST);
  gl.enable(GL.BLEND);
  gl.blendFunc(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA);
}
