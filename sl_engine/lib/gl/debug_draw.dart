import 'dart:js_interop';
import 'dart:typed_data';

import 'package:sl_engine/gl/gl.dart';
import 'package:sl_engine/gl/mesh.dart';
import 'package:sl_engine/gl/shader.dart';
import 'package:vector_math/vector_math.dart';
import 'package:web/web.dart' as web;

class DebugDraw {
  static late final Shader _pointShader;
  static late final Shader _box2DShader;
  static late final Shader _box3DShader;

  static late final web.WebGLVertexArrayObject _vao;
  static late final web.WebGLBuffer _vbo;

  static late final Mesh _cubeMesh;

  static Future<void> init() async {
    _pointShader = (await Shader.load('shaders/debug/point'))!;
    _box2DShader = (await Shader.load('shaders/debug/box_2d'))!;
    _box3DShader = (await Shader.load('shaders/debug/box_3d'))!;

    _vao = gl.createVertexArray()!;
    gl.bindVertexArray(_vao);
    _vbo = gl.createBuffer()!;
    gl.bindBuffer(GL.ARRAY_BUFFER, _vbo);
    gl.bufferData(GL.ARRAY_BUFFER, Float32List.fromList([0.0, 0.0, 0.0]).toJS, GL.STATIC_DRAW);

    gl.enableVertexAttribArray(0);
    gl.vertexAttribPointer(0, 3, GL.FLOAT, false, 0, 0);

    _cubeMesh = CubeMesh();
  }

  static void drawPoint(Vector3 position, {Vector4? color, double size = 4.0}) {
    _pointShader.bind();
    _pointShader.setUniform('u_point', position);
    _pointShader.setUniform('u_color', color ?? Vector4(1.0, 1.0, 1.0, 1.0));
    _pointShader.setUniform('u_size', size);
    gl.bindVertexArray(_vao);
    gl.drawArrays(GL.POINTS, 0, 1);
  }

  static void drawBox2D({required Vector2Int start, required Vector2Int size, Vector4? color}) {
    final matrix = makeOrthographicMatrix(0.0, canvas.width.toDouble(), canvas.height.toDouble(), 0.0, -1.0, 1.0)
      ..translateByVector3(Vector3(start.$1.toDouble(), start.$2.toDouble(), 0.0))
      ..scaleByVector3(Vector3(size.$1.toDouble(), size.$2.toDouble(), 1.0));

    _box2DShader.bind();
    _box2DShader.setUniform('u_matrix', matrix);
    _box2DShader.setUniform('u_color', color ?? Vector4(1.0, 1.0, 1.0, 1.0));
    gl.bindVertexArray(_vao);
    gl.drawArrays(GL.TRIANGLES, 0, 6);
  }

  static void drawBox3D({required Vector3 center, required Vector3 size, Quaternion? rotation, Vector4? color}) {
    final matrix = Matrix4.compose(center, rotation ?? Quaternion.identity(), size);

    _box3DShader.bind();
    _box3DShader.setUniform('u_modelMat', matrix);
    _box3DShader.setUniform('u_color', color ?? Vector4(1.0, 1.0, 1.0, 1.0));
    _cubeMesh.bind();
    _cubeMesh.draw();
  }
}
