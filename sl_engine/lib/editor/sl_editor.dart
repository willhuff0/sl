import 'dart:js_interop';

import 'package:sl_engine/editor/fly_camera.dart';
import 'package:sl_engine/editor/selector.dart';
import 'package:sl_engine/gl/debug_draw.dart';
import 'package:sl_engine/gl/gl.dart';
import 'package:sl_engine/gl/sl.dart';
import 'package:sl_engine/input.dart';
import 'package:sl_engine/utils/renderer.dart';
import 'package:vector_math/vector_math.dart';
import 'package:web/web.dart' as web;

class SLEditor {
  static FlyCamera? _camera;

  static FlyCamera? get camera => _camera;

  static Future<void> initSlEditorMode(web.HTMLCanvasElement canvas_) async {
    canvas_.onContextMenu.listen((event) {
      event.preventDefault();
    });

    initGl(canvas_);
    SL.init();
    Input.init(editorMode: true);

    _camera = FlyCamera(
      position: Vector3(0.0, 4.0, 5.0),
      yaw: -90.0,
      pitch: -45.0,
    );

    Renderer.init();
    await DebugDraw.init();
    await Selector.init(_camera!);

    web.window.requestAnimationFrame(_frame.toJS);
  }

  static num? _lastTime;
  static void _frame(num time) {
    double dt;
    if (_lastTime == null) {
      dt = 0.0;
    } else {
      dt = (time - _lastTime!) / 1000.0;
    }
    _lastTime = time;

    _tick(time.toDouble() / 1000.0, dt);
    _render();

    web.window.requestAnimationFrame(_frame.toJS);
  }

  static void _tick(double time, double dt) {
    _camera!.tick(dt);

    Input.postTick();
  }

  static void _render() {
    resizeCanvas();
    _setEngineUbo();
    _bindAndClearCanvas();

    Renderer.renderAll();
    Selector.draw();
  }

  static void _setEngineUbo() {
    final (viewPos, viewMat, projMat) = _camera!.getState()!;
    final viewProjMat = projMat * viewMat;

    SL.setUniforms(
      SLUniforms(
        viewProjMat: viewProjMat,
        viewMat: viewMat,
        viewPos: viewPos,
      ),
    );
  }

  static void _bindAndClearCanvas() {
    gl.bindFramebuffer(GL.FRAMEBUFFER, defaultFramebuffer);
    gl.clearColor(0.1, 0.1, 0.1, 1.0);
    gl.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT);
  }
}
