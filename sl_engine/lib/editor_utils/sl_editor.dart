import 'dart:js_interop';

import 'package:sl_engine/editor_utils/fly_camera.dart';
import 'package:sl_engine/editor_utils/selector.dart';
import 'package:sl_engine/event_loop.dart';
import 'package:sl_engine/gl/debug_draw.dart';
import 'package:sl_engine/gl/gl.dart';
import 'package:sl_engine/gl/sl.dart';
import 'package:sl_engine/input.dart';
import 'package:sl_engine/utils/renderer.dart';
import 'package:vector_math/vector_math.dart';
import 'package:web/web.dart' as web;

class SLEditor {
  static FlyCamera? _camera;

  FlyCamera? get camera => _camera;

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

    web.window.requestAnimationFrame(_frame.toJS);
  }

  static void _tick(double time, double dt) {}
}
