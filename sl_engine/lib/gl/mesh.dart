import 'dart:js_interop';
import 'dart:typed_data';

import 'package:sl_engine/gl/buffer.dart';
import 'package:sl_engine/gl/gl.dart';
import 'package:web/web.dart' hide Float32List;

abstract interface class Mesh {
  void bind();
  void draw();
  void unbind();
}

final _cubeVertices = Float32List.fromList([
  // Front face (Normal: 0,0,1)
  -0.5, -0.5, 0.5, 0.0, 0.0, 1.0, 0.0, 0.0, // 0
  0.5, -0.5, 0.5, 0.0, 0.0, 1.0, 1.0, 0.0, // 1
  0.5, 0.5, 0.5, 0.0, 0.0, 1.0, 1.0, 1.0, // 2
  -0.5, 0.5, 0.5, 0.0, 0.0, 1.0, 0.0, 1.0, // 3
  // Back face (Normal: 0,0,-1)
  -0.5, -0.5, -0.5, 0.0, 0.0, -1.0, 1.0, 0.0, // 4
  -0.5, 0.5, -0.5, 0.0, 0.0, -1.0, 1.0, 1.0, // 5
  0.5, 0.5, -0.5, 0.0, 0.0, -1.0, 0.0, 1.0, // 6
  0.5, -0.5, -0.5, 0.0, 0.0, -1.0, 0.0, 0.0, // 7
  // Top face (Normal: 0,1,0)
  -0.5, 0.5, -0.5, 0.0, 1.0, 0.0, 0.0, 1.0, // 8
  -0.5, 0.5, 0.5, 0.0, 1.0, 0.0, 0.0, 0.0, // 9
  0.5, 0.5, 0.5, 0.0, 1.0, 0.0, 1.0, 0.0, // 10
  0.5, 0.5, -0.5, 0.0, 1.0, 0.0, 1.0, 1.0, // 11
  // Bottom face (Normal: 0,-1,0)
  -0.5, -0.5, -0.5, 0.0, -1.0, 0.0, 1.0, 1.0, // 12
  0.5, -0.5, -0.5, 0.0, -1.0, 0.0, 0.0, 1.0, // 13
  0.5, -0.5, 0.5, 0.0, -1.0, 0.0, 0.0, 0.0, // 14
  -0.5, -0.5, 0.5, 0.0, -1.0, 0.0, 1.0, 0.0, // 15
  // Right face (Normal: 1,0,0)
  0.5, -0.5, -0.5, 1.0, 0.0, 0.0, 1.0, 0.0, // 16
  0.5, 0.5, -0.5, 1.0, 0.0, 0.0, 1.0, 1.0, // 17
  0.5, 0.5, 0.5, 1.0, 0.0, 0.0, 0.0, 1.0, // 18
  0.5, -0.5, 0.5, 1.0, 0.0, 0.0, 0.0, 0.0, // 19
  // Left face (Normal: -1,0,0)
  -0.5, -0.5, -0.5, -1.0, 0.0, 0.0, 0.0, 0.0, // 20
  -0.5, -0.5, 0.5, -1.0, 0.0, 0.0, 1.0, 0.0, // 21
  -0.5, 0.5, 0.5, -1.0, 0.0, 0.0, 1.0, 1.0, // 22
  -0.5, 0.5, -0.5, -1.0, 0.0, 0.0, 0.0, 1.0, // 23
]);

final _cubeIndices = Uint16List.fromList([
  0, 1, 2, 2, 3, 0, // Front
  4, 5, 6, 6, 7, 4, // Back
  8, 9, 10, 10, 11, 8, // Top
  12, 13, 14, 14, 15, 12, // Bottom
  16, 17, 18, 18, 19, 16, // Right
  20, 21, 22, 22, 23, 20, // Left
]);

final class CubeMesh extends Mesh {
  late final WebGLVertexArrayObject _vao;
  late final Buffer _vertexBuffer;
  late final Buffer _indexBuffer;

  CubeMesh() {
    _vao = gl.createVertexArray()!;
    gl.bindVertexArray(_vao);

    _vertexBuffer = Buffer(GL.ARRAY_BUFFER);
    _vertexBuffer.bind();
    _vertexBuffer.write(_cubeVertices.toJS, GL.STATIC_DRAW);

    _indexBuffer = Buffer(GL.ELEMENT_ARRAY_BUFFER);
    _indexBuffer.bind();
    _indexBuffer.write(_cubeIndices.toJS, GL.STATIC_DRAW);

    gl.enableVertexAttribArray(0);
    gl.enableVertexAttribArray(1);
    gl.enableVertexAttribArray(2);

    gl.vertexAttribPointer(0, 3, GL.FLOAT, false, 4 * 8, 0);
    gl.vertexAttribPointer(1, 3, GL.FLOAT, false, 4 * 8, 4 * 3);
    gl.vertexAttribPointer(2, 2, GL.FLOAT, false, 4 * 8, 4 * 6);
  }

  @override
  void bind() {
    gl.bindVertexArray(_vao);
  }

  @override
  void draw() {
    gl.drawElements(GL.TRIANGLES, _cubeIndices.length, GL.UNSIGNED_SHORT, 0);
  }

  @override
  void unbind() {
    gl.bindVertexArray(null);
  }
}
