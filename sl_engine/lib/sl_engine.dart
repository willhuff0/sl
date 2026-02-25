import 'dart:js_interop';
import 'dart:typed_data';

import 'package:sl_engine/gl/gl.dart';
import 'package:sl_engine/gl/mesh.dart';
import 'package:sl_engine/outliner.dart';
import 'package:sl_engine/gl/sl.dart';
import 'package:vector_math/vector_math.dart';
import 'package:web/web.dart' as web;

late final Mesh _mesh;
late final Outliner _outliner;

void initialize(web.HTMLCanvasElement canvas_) async {
  initGl(canvas_);
  SL.init();

  _mesh = CubeMesh();
  _outliner = await Outliner.create();
  _outliner.canvasSizeChanged(canvas.width, canvas.height);

  gl.enable(GL.DEPTH_TEST);
  gl.enable(GL.BLEND);
  gl.blendFunc(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA);

  web.window.requestAnimationFrame(frame.toJS);
}

void frame(num time) {
  final width = canvas.clientWidth;
  final height = canvas.clientHeight;
  if (canvas.width != width || canvas.height != height) {
    canvas.width = width;
    canvas.height = height;
    gl.viewport(0, 0, width, height);
    _outliner.canvasSizeChanged(width, height);
  }
  final aspectRatio = width / height;

  gl.clearColor(0.1, 0.1, 0.1, 1.0);
  gl.clear(web.WebGL2RenderingContext.COLOR_BUFFER_BIT | web.WebGL2RenderingContext.DEPTH_BUFFER_BIT);

  final projectionMatrix = makePerspectiveMatrix(radians(60.0), aspectRatio, 0.1, 100.0);
  final viewMatrix = makeViewMatrix(
    Vector3(2.0, 2.0, 2.0), // Camera position
    Vector3(0.0, 0.0, 0.0), // Target
    Vector3(0.0, 1.0, 0.0), // Up
  );

  SL.setUniforms(
    SLUniforms(
      viewProjMat: projectionMatrix * viewMatrix,
    ),
  );

  final matrix = Matrix4.identity();
  matrix.rotateY(time / 1000 * 0.2);

  _outliner.test(_mesh, matrix);
  _outliner.render(_mesh, matrix, Vector4(1.0, 0.7, 0.0, 1.0));

  web.window.requestAnimationFrame(frame.toJS);
}
