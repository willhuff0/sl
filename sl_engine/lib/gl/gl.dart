import 'dart:async';
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

final _canvasSizeChangedController = StreamController<(int, int)>.broadcast();
final slCanvasSizeChanged = _canvasSizeChangedController.stream;

typedef Vector2Int = (int, int);
typedef Vector3Int = (int, int, int);
typedef Vector4Int = (int, int, int, int);

typedef Vector2Bool = (bool, bool);
typedef Vector3Bool = (bool, bool, bool);
typedef Vector4Bool = (bool, bool, bool, bool);

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
  gl.enable(GL.SAMPLE_ALPHA_TO_COVERAGE);
  gl.blendFunc(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA);
}

void resizeCanvas() {
  final width = canvas.clientWidth;
  final height = canvas.clientHeight;
  if (canvas.width != width || canvas.height != height) {
    canvas.width = width;
    canvas.height = height;
    gl.viewport(0, 0, width, height);
    _canvasSizeChangedController.add((width, height));
  }
}
