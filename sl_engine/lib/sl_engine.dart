import 'dart:js_interop';
import 'dart:math';

import 'package:sl_engine/editor_utils/fly_camera.dart';
import 'package:sl_engine/gl/debug_draw.dart';
import 'package:sl_engine/gl/gl.dart';
import 'package:sl_engine/gl/gltf_loader.dart';
import 'package:sl_engine/gl/mesh.dart';
import 'package:sl_engine/gl/shader.dart';
import 'package:sl_engine/input.dart';
import 'package:sl_engine/node.dart';
import 'package:sl_engine/editor_utils/selector.dart';
import 'package:sl_engine/gl/sl.dart';
import 'package:sl_engine/utils/renderer.dart';
import 'package:vector_math/vector_math.dart';
import 'package:web/web.dart' as web;

final Node root = Node(name: 'Example Scene');
late final List<Node> _cubes;
late final Shader _shader;

late final GLTF? _testGltf;

late final FlyCamera _flyCamera;

void initialize(web.HTMLCanvasElement canvas_) async {
  initGl(canvas_);
  SL.init();
  Input.init(editorMode: true);

  await DebugDraw.init();

  await Selector.init();

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

  _flyCamera = FlyCamera(
    position: Vector3(0.0, 4.0, 5.0),
    yaw: -90.0,
    pitch: -45.0,
  );

  root.enterScene();

  web.window.requestAnimationFrame(frame.toJS);
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

  final (viewPos, viewMat, projMat) = _flyCamera.tick(dt);
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

  for (final cube in _cubes) {
    cube.lRot = Quaternion.axisAngle(Vector3(0.0, 0.0, 1.0), time / 1000 * 0.2);
  }

  _testGltf!.root.lRot = Quaternion.axisAngle(Vector3(0.0, 0.0, 1.0), time / 1000 * 0.2);

  // root.lRot = Quaternion.axisAngle(Vector3(0.0, 1.0, 0.0), time / 1000 * 0.2);

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
