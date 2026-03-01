import 'dart:async';
import 'dart:js_interop';
import 'dart:math';

import 'package:sl_engine/editor_utils/fly_camera.dart';
import 'package:sl_engine/gl/debug_draw.dart';
import 'package:sl_engine/gl/gl.dart';
import 'package:sl_engine/gl/gltf_loader.dart';
import 'package:sl_engine/gl/mesh.dart';
import 'package:sl_engine/gl/shader.dart';
import 'package:sl_engine/gl/xr.dart';
import 'package:sl_engine/input.dart';
import 'package:sl_engine/node.dart';
import 'package:sl_engine/editor_utils/selector.dart';
import 'package:sl_engine/gl/sl.dart';
import 'package:sl_engine/utils/renderer.dart';
import 'package:vector_math/vector_math.dart';
import 'package:web/web.dart' as web;
import 'package:webxr/webxr.dart';

final Node root = Node(name: 'Example Scene');
late final List<Node> _cubes;
late final Shader _shader;

late final GLTF? _testGltf;

late final FlyCamera _flyCamera;

// /// Interface [XRRenderStateInit]
// extension type XRRenderStateInit(JSObject _) implements JSObject {
//   /// Property [baseLayer]
//   ///
//   /// baseLayer?: XRWebGLLayer | undefined
//   external XRWebGLLayer? baseLayer;

//   /// Property [depthFar]
//   ///
//   /// depthFar?: number | undefined
//   external JSNumber? depthFar;

//   /// Property [depthNear]
//   ///
//   /// depthNear?: number | undefined
//   external JSNumber? depthNear;

//   /// Property [inlineVerticalFieldOfView]
//   ///
//   /// inlineVerticalFieldOfView?: number | undefined
//   external JSNumber? inlineVerticalFieldOfView;

//   /// Property [layers]
//   ///
//   /// layers?: XRLayer[] | undefined
//   external JSArray<XRLayer>? layers;
// }

void initialize(web.HTMLCanvasElement canvas_) async {
  final vrSupported = await initVr();

  initGl(canvas_, vr: vrSupported);
  SL.init();
  // Input.init(editorMode: true);

  // await DebugDraw.init();

  // await Selector.init();

  gl.enable(GL.DEPTH_TEST);
  gl.enable(GL.BLEND);
  gl.blendFunc(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA);

  final mesh = CubeMesh();
  _cubes = List.generate(
    10,
    (i) {
      final node = Node(
        name: 'Cube $i',
        pos: Vector3(cos(i * 0.6) * 3.0, sin(i * 0.05 + 0.2) * 0.1, sin(i * 0.6) * 3.0),
      );
      Renderer.addMeshToNode(node, mesh);
      root.addChild(node);
      return node;
    },
  );

  _shader = (await Shader.load('shaders/test'))!;

  _testGltf = await GLTF.load('models/arrow.glb');
  // _testGltf = await GLTF.load('models/gltf/arrow.gltf');
  _testGltf!.root.lScale = Vector3(0.05, 0.05, 0.05);

  // _flyCamera = FlyCamera(
  //   position: Vector3(0.0, 4.0, 5.0),
  //   yaw: -90.0,
  //   pitch: -45.0,
  // );

  root.enterScene();

  if (vrSupported) {
    StreamSubscription? onClickSubscription;
    onClickSubscription = canvas.onClick.listen((_) async {
      onClickSubscription!.cancel();
      await beginVrSession();

      final glLayer = XRWebGLLayer(xrSession, gl);

      final renderState = XRRenderStateInit.$(JSObject());
      renderState.baseLayer = glLayer;

      // TODO: change to   external _i1.JSVoid updateRenderState([XRRenderStateInit renderStateInit]);
      xrSession.updateRenderState(renderState);

      xrSession.requestAnimationFrame(xrFrame.toJS);
    });
  } else {
    web.window.requestAnimationFrame(frame.toJS);
  }
}

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

  _flyCamera.tick(dt);
  final (viewPos, viewMat, projMat) = _flyCamera.getState();
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
  Renderer.renderAll(
    bindUniformsCallback: (node) {
      _shader.setUniform('u_modelMat', node.getMatrix());
      _shader.setUniform('u_normalMat', node.getMatrix().getNormalMatrix());
    },
  );
  Renderer.renderUnregisteredNode(
    _testGltf!.root,
    bindUniformsCallback: (node) {
      _shader.setUniform('u_modelMat', node.getMatrix());
      _shader.setUniform('u_normalMat', node.getMatrix().getNormalMatrix());
    },
  );
  Selector.draw();

  Input.postTick();
  web.window.requestAnimationFrame(frame.toJS);
}

void xrFrame(num time, XRFrame xrFrameData) {
  double dt;
  if (_lastTime == null) {
    dt = 0.0;
  } else {
    dt = (time - _lastTime!) / 1000.0;
  }
  _lastTime = time;

  tick(time.toDouble(), dt);

  final glLayer = xrSession.renderState.baseLayer!;
  final pose = xrFrameData.getViewerPose(xrReferenceSpace);
  if (pose != null) {
    gl.bindFramebuffer(GL.FRAMEBUFFER, glLayer.framebuffer);

    gl.clearColor(0.1, 0.1, 0.1, 1.0);
    gl.clear(web.WebGL2RenderingContext.COLOR_BUFFER_BIT | web.WebGL2RenderingContext.DEPTH_BUFFER_BIT);

    for (final jsView in pose.views.toDart) {
      final view = jsView as XRView;
      final viewport = glLayer.getViewport(view)!;

      gl.viewport(viewport.x, viewport.y, viewport.width, viewport.height);

      final viewMat = Matrix4.fromList(view.transform.matrix.toDart)..invert();
      final projMat = Matrix4.fromList(view.projectionMatrix.toDart);
      final viewProjMat = projMat * viewMat;

      final viewPosJs = view.transform.position;
      final viewPos = Vector3(viewPosJs.x, viewPosJs.y, viewPosJs.z);

      SL.setUniforms(
        SLUniforms(
          viewProjMat: viewProjMat,
          viewMat: viewMat,
          viewPos: viewPos,
        ),
      );

      _shader.bind();
      Renderer.renderAll(
        bindUniformsCallback: (node) {
          _shader.setUniform('u_modelMat', node.getMatrix());
          _shader.setUniform('u_normalMat', node.getMatrix().getNormalMatrix());
        },
      );
    }
  }

  xrSession.requestAnimationFrame(xrFrame.toJS);
}

void tick(double time, double dt) {
  for (final cube in _cubes) {
    cube.lRot = Quaternion.axisAngle(Vector3(0.0, 0.0, 1.0), time / 1000 * 0.2);
  }

  _testGltf!.root.lRot = Quaternion.axisAngle(Vector3(0.0, 0.0, 1.0), time / 1000 * 0.2);

  // root.lRot = Quaternion.axisAngle(Vector3(0.0, 1.0, 0.0), time / 1000 * 0.2);
}
