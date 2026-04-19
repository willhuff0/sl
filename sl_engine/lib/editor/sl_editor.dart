import 'dart:js_interop';

import 'package:sl_engine/components/physics_component.dart';
import 'package:sl_engine/editor/fly_camera.dart';
import 'package:sl_engine/editor/model_preview_generator.dart';
import 'package:sl_engine/editor/selector.dart';
import 'package:sl_engine/gl/debug_draw.dart';
import 'package:sl_engine/gl/directional_light.dart';
import 'package:sl_engine/gl/gl.dart';
import 'package:sl_engine/gl/gltf.dart';
import 'package:sl_engine/gl/skybox.dart';
import 'package:sl_engine/gl/sl.dart';
import 'package:sl_engine/input.dart';
import 'package:sl_engine/utils/physics.dart';
import 'package:sl_engine/utils/renderer.dart';
import 'package:vector_math/vector_math.dart';
import 'package:web/web.dart' as web;

class SLEditor {
  static FlyCamera? _camera;
  static ModelPreviewGenerator? _modelPreviewGenerator;
  static Skybox? _skybox;
  static DirectionalLight? _directionalLight;

  static FlyCamera? get camera => _camera;
  static ModelPreviewGenerator? get modelPreviewGenerator => _modelPreviewGenerator;
  static Skybox? get skybox => _skybox;

  static Future<void> initSlEditorMode(web.HTMLCanvasElement canvas_) async {
    canvas_.onContextMenu.listen((event) {
      event.preventDefault();
    });

    initGl(canvas_);
    SL.init();
    Input.init(editorMode: true);

    _camera = FlyCamera(
      position: Vector3(7.0, -4.0, 8.0),
      yaw: -90.0 - 45.0,
      pitch: -15.0,
      near: 0.1,
      far: 500.0,
    );

    Renderer.init();
    await DebugDraw.init();
    await Selector.init(_camera!);
    _modelPreviewGenerator = await ModelPreviewGenerator.create();
    Physics.init();

    final hdri = (await HDRI.loadFromHdr('skybox_02.hdr'))!;
    _skybox = await Skybox.fromHdri(hdri);

    _directionalLight = await DirectionalLight.create();
    _directionalLight!.bindUbo();

    final model = (await GLTF.load('models/FlightHelmet.glb'))!;
    model.root.lScale = Vector3.all(4.0);
    model.root.addComponent(PhysicsComponent.fromNodeBounds(model.root));
    model.root.enterScene();

    final model2 = (await GLTF.load('models/DamagedHelmet.glb'))!;
    model2.root.lPos = Vector3(0.0, 4.0, 0.0);
    model2.root.addComponent(PhysicsComponent.fromSphere(radius: 1.0, pivot: Vector3(0.0, -0.2, 0.0)));
    model2.root.enterScene();

    final model3 = (await GLTF.load('models/ABeautifulGame.glb'))!;
    model3.root.lPos = Vector3(-0.0, 6.5, 0.0);
    model3.root.lScale = Vector3.all(4.0);
    // model3.root.addComponent(PhysicsComponent.fromNodeBounds(model3.root));
    for (final child in model3.root.children) {
      child.updateWorldFromParent();
      child.addComponent(PhysicsComponent.fromNodeBounds(child));
      child.lScale = Vector3.all(4.0);
      child.enterScene();
    }
    model3.root.removeAllChildren();
    // model3.root.enterScene();

    final floor = (await GLTF.load('models/Floor.glb'))!;
    floor.root.lPos = Vector3(0.0, -10.0, 0.0);
    floor.root.lScale = Vector3.all(1.0);
    floor.root.addComponent(PhysicsComponent.fromNodeBounds(floor.root, move: false));
    floor.root.enterScene();

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

    // if (Input.isKeyDown(Key.t)) {
    Physics.tick(dt);
    // }

    Input.postTick();
  }

  static void _render() {
    resizeCanvas();
    _setEngineUbo();
    _bindAndClearCanvas();

    _directionalLight!.drawShadowMap();
    _directionalLight!.bindShadowMap();

    _skybox!.bindIblMaps();
    _skybox!.draw();

    DebugDraw.drawPoint(Vector3(0.0, 0.0, 0.0), size: 4);

    Renderer.renderAll();
    // final (viewPos, viewMat, projMat) = _camera!.getState()!;
    // Renderer.drawAllBounds(viewMat);
    Selector.draw();

    // Physics.drawDebugShapes();

    // _directionalLight!.shadowMap.drawDebugView(size: 256);
  }

  static void _setEngineUbo() {
    final (viewPos, viewMat, projMat) = _camera!.getState()!;
    final viewProjMat = projMat * viewMat;

    _directionalLight!.regenerateLightSpaceMatrices(
      cameraViewMat: viewMat,
      cameraNear: _camera!.near,
      cameraFar: _camera!.far,
      fovRad: radians(_camera!.fov),
      aspect: canvas.width / canvas.height,
    );

    SL.setUniforms(
      SLUniforms(
        viewProjMat: viewProjMat,
        projMat: projMat,
        viewMat: viewMat,
        viewPos: viewPos,
        radianceMipLevelCount: _skybox!.radianceMap.mipLevelCount,
      ),
    );
  }

  static void _bindAndClearCanvas() {
    gl.bindFramebuffer(GL.FRAMEBUFFER, defaultFramebuffer);
    gl.clearColor(0.0, 0.0, 0.0, 1.0);
    gl.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT);
  }
}
