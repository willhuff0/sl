import 'dart:js_interop';
import 'dart:typed_data';

import 'package:sl_engine/gl/gl.dart';
import 'package:sl_engine/gl/shader.dart';
import 'package:vector_math/vector_math.dart';
import 'package:web/web.dart' as web;

class DebugDraw {
  static late final Shader _shader;
  static late final web.WebGLVertexArrayObject _vao;
  static late final web.WebGLBuffer _vbo;

  static Future<void> init() async {
    _shader = (await Shader.load('shaders/debug/debug'))!;

    _vao = gl.createVertexArray()!;
    gl.bindVertexArray(_vao);
    _vbo = gl.createBuffer()!;
    gl.bindBuffer(GL.ARRAY_BUFFER, _vbo);
    gl.bufferData(GL.ARRAY_BUFFER, Float32List.fromList([0.0, 0.0, 0.0]).toJS, GL.STATIC_DRAW);

    gl.enableVertexAttribArray(0);
    gl.vertexAttribPointer(0, 3, GL.FLOAT, false, 0, 0);
  }

  static void drawPoint(Vector3 position, {Vector4? color, double size = 4.0}) {
    _shader.bind();
    _shader.setUniform('u_point', position);
    _shader.setUniform('u_color', color ?? Vector4(1.0, 1.0, 1.0, 1.0));
    _shader.setUniform('u_size', size);
    gl.bindVertexArray(_vao);
    gl.drawArrays(GL.POINTS, 0, 1);
  }
}
