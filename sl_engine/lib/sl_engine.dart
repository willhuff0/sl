import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

late final web.WebGL2RenderingContext gl;
web.WebGLProgram? program;
web.WebGLVertexArrayObject? vao;
web.WebGLUniformLocation? uAspectRatio;
web.WebGLUniformLocation? uMouse;

double mouseX = 0.0;
double mouseY = 0.0;
double aspectRatio = 1.0;
late web.HTMLCanvasElement _canvas;

const vertexSource = '''#version 300 es
in vec2 a_position;
uniform vec2 u_mouse;
uniform float u_aspectRatio;
void main() {
    vec2 pos = a_position;
    // Scale x by aspect ratio to maintain shape if we want consistent size visually
    // or correct coordinate space. Let's correct coordinate space so square is square.
    // Actually, usually we fix aspect ratio in projection matrix.
    // For specific requirement "corrected for aspect ratio", we usually mean 
    // adapting drawing space. 
    
    // We will apply aspect ratio correction to the final position.
    // Let's assume the canvas covers -1 to 1 in Y.
    
    vec2 finalPos = pos + u_mouse;
    finalPos.x /= u_aspectRatio;
    
    gl_Position = vec4(finalPos, 0.0, 1.0);
}
''';

const fragmentSource = '''#version 300 es
precision highp float;
out vec4 outColor;
void main() {
    outColor = vec4(1.0, 0.5, 0.2, 1.0);
}
''';

void initialize(web.HTMLCanvasElement canvas) {
  _canvas = canvas;
  final context =
      canvas.getContext(
            'webgl2',
            {
              'powerPreference': 'high-performance',
              'antialias': true,
            }.jsify(),
          )
          as web.WebGL2RenderingContext?;
  if (context == null) throw Exception('Failed to get WebGL2 context!');
  gl = context;

  // Setup Shaders
  final vs = _createShader(web.WebGL2RenderingContext.VERTEX_SHADER, vertexSource);
  final fs = _createShader(web.WebGL2RenderingContext.FRAGMENT_SHADER, fragmentSource);
  program = _createProgram(vs, fs);

  uAspectRatio = gl.getUniformLocation(program!, 'u_aspectRatio');
  uMouse = gl.getUniformLocation(program!, 'u_mouse');

  // Setup Triangle
  final vertices = Float32List.fromList([
    0.0,
    0.1,
    -0.1,
    -0.1,
    0.1,
    -0.1,
  ]);

  vao = gl.createVertexArray();
  gl.bindVertexArray(vao);

  final buffer = gl.createBuffer();
  gl.bindBuffer(web.WebGL2RenderingContext.ARRAY_BUFFER, buffer);
  gl.bufferData(web.WebGL2RenderingContext.ARRAY_BUFFER, vertices.toJS, web.WebGL2RenderingContext.STATIC_DRAW);

  final aPosition = gl.getAttribLocation(program!, 'a_position');
  gl.enableVertexAttribArray(aPosition);
  gl.vertexAttribPointer(aPosition, 2, web.WebGL2RenderingContext.FLOAT, false, 0, 0);

  // Input Handling
  web.document.addEventListener(
    'mousemove',
    (web.MouseEvent e) {
      final rect = canvas.getBoundingClientRect();
      final x = e.clientX - rect.left;
      final y = e.clientY - rect.top;

      // Convert to Normalized Device Coordinates (-1 to +1), Y is inverted
      mouseX = (x / rect.width) * 2 - 1;
      mouseY = -((y / rect.height) * 2 - 1);

      // Adjust mouse X interaction by aspect ratio so movement 1:1 tracks with cursor visually
      mouseX *= (rect.width / rect.height);
    }.toJS,
  );

  web.window.requestAnimationFrame(frame.toJS);
}

web.WebGLShader _createShader(int type, String source) {
  final shader = gl.createShader(type)!;
  gl.shaderSource(shader, source);
  gl.compileShader(shader);
  if (!(gl.getShaderParameter(shader, web.WebGL2RenderingContext.COMPILE_STATUS) as bool)) {
    throw Exception(gl.getShaderInfoLog(shader));
  }
  return shader;
}

web.WebGLProgram _createProgram(web.WebGLShader vs, web.WebGLShader fs) {
  final prog = gl.createProgram()!;
  gl.attachShader(prog, vs);
  gl.attachShader(prog, fs);
  gl.linkProgram(prog);
  if (!(gl.getProgramParameter(prog, web.WebGL2RenderingContext.LINK_STATUS) as bool)) {
    throw Exception(gl.getProgramInfoLog(prog));
  }
  return prog;
}

void frame(num time) {
  // Resize canvas if needed
  final width = _canvas.clientWidth;
  final height = _canvas.clientHeight;
  if (_canvas.width != width || _canvas.height != height) {
    _canvas.width = width;
    _canvas.height = height;
    gl.viewport(0, 0, width, height);
  }

  aspectRatio = width / height;

  gl.clearColor(0.1, 0.1, 0.1, 1.0);
  gl.clear(web.WebGL2RenderingContext.COLOR_BUFFER_BIT);

  gl.useProgram(program);
  gl.uniform1f(uAspectRatio, aspectRatio);
  gl.uniform2f(uMouse, mouseX, mouseY);

  gl.bindVertexArray(vao);
  gl.drawArrays(web.WebGL2RenderingContext.TRIANGLES, 0, 3);

  web.window.requestAnimationFrame(frame.toJS);
}
