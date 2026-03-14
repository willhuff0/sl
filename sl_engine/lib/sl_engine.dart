import 'dart:js_interop';

import 'package:sl_engine/components/mesh_component.dart';
import 'package:sl_engine/editor_utils/fly_camera.dart';
import 'package:sl_engine/gl/debug_draw.dart';
import 'package:sl_engine/gl/gl.dart';
import 'package:sl_engine/gl/mesh.dart';
import 'package:sl_engine/gl/shader.dart';
import 'package:sl_engine/input.dart';
import 'package:sl_engine/node.dart';
import 'package:sl_engine/editor_utils/selector.dart';
import 'package:sl_engine/gl/sl.dart';
import 'package:sl_engine/utils/renderer.dart';
import 'package:vector_math/vector_math.dart';
import 'package:web/web.dart' as web;

num? _lastTime;

void frame(num time) {
  double dt;
  if (_lastTime == null) {
    dt = 0.0;
  } else {
    dt = (time - _lastTime!) / 1000.0;
  }
  _lastTime = time;

  tick(time.toDouble(), dt);

  _flyCamera!.tick(dt);
  final (viewPos, viewMat, projMat) = _flyCamera!.getState()!;
  final viewProjMat = projMat * viewMat;

  final width = canvas.clientWidth;
  final height = canvas.clientHeight;
  if (canvas.width != width || canvas.height != height) {
    canvas.width = width;
    canvas.height = height;
    gl.viewport(0, 0, width, height);

    Selector.canvasSizeChanged(width, height);
  }

  gl.clearColor(0.1, 0.1, 0.1, 1.0);
  gl.clear(web.WebGL2RenderingContext.COLOR_BUFFER_BIT | web.WebGL2RenderingContext.DEPTH_BUFFER_BIT);

  SL.setUniforms(
    SLUniforms(
      viewProjMat: viewProjMat,
      viewMat: viewMat,
      viewPos: viewPos,
    ),
  );

  _shader.bind();
  Renderer.renderAllCustomShader(
    bindUniformsCallback: (node) {
      _shader.setUniform('u_modelMat', node.getMatrix());
      _shader.setUniform('u_normalMat', node.getMatrix().getNormalMatrix());
    },
  );
  Selector.draw();

  Input.postTick();
  web.window.requestAnimationFrame(frame.toJS);
}

void tick(double time, double dt) {}
