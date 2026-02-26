import 'dart:js_interop';
import 'dart:math';

import 'package:sl_engine/gl/gl.dart';
import 'package:sl_engine/gl/mesh.dart';
import 'package:sl_engine/gl/shader.dart';
import 'package:sl_engine/node.dart';
import 'package:sl_engine/selector.dart';
import 'package:sl_engine/utils/clicker.dart';
import 'package:sl_engine/gl/sl.dart';
import 'package:sl_engine/utils/renderer.dart';
import 'package:vector_math/vector_math.dart';
import 'package:web/web.dart' as web;

final Node root = Node(name: 'Example Scene');
late final List<Node> _cubes;
late final Clicker _clicker;

late final Shader _shader;

void initialize(web.HTMLCanvasElement canvas_) async {
  initGl(canvas_);
  SL.init();

  _clicker = await Clicker.create();
  _clicker.canvasSizeChanged(canvas.width, canvas.height);

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

  canvas.onClick.listen((event) {
    final rect = canvas.getBoundingClientRect();
    final x = event.clientX - rect.left.toInt();
    final y = event.clientY - rect.top.toInt();
    Selector.selectOnly(_clicker.click(x, y));
  });

  web.window.requestAnimationFrame(frame.toJS);
}

void frame(num time) {
  final width = canvas.clientWidth;
  final height = canvas.clientHeight;
  if (canvas.width != width || canvas.height != height) {
    canvas.width = width;
    canvas.height = height;
    gl.viewport(0, 0, width, height);

    Selector.canvasSizeChanged(width, height);
    _clicker.canvasSizeChanged(width, height);
  }
  final aspectRatio = width / height;

  gl.clearColor(0.1, 0.1, 0.1, 1.0);
  gl.clear(web.WebGL2RenderingContext.COLOR_BUFFER_BIT | web.WebGL2RenderingContext.DEPTH_BUFFER_BIT);

  final projectionMatrix = makePerspectiveMatrix(radians(60.0), aspectRatio, 0.1, 100.0);
  final viewMatrix = makeViewMatrix(
    Vector3(0.0, 4.0, 5.0), // Camera position
    Vector3(0.0, -1.0, 0.0), // Target
    Vector3(0.0, 1.0, 0.0), // Up
  );

  SL.setUniforms(
    SLUniforms(
      viewProjMat: projectionMatrix * viewMatrix,
    ),
  );

  for (final cube in _cubes) {
    cube.lRot = Quaternion.axisAngle(Vector3(0.0, 1.0, 0.0), time / 1000 * 0.2);
  }

  _shader.bind();
  Renderer.renderWithCustomShader(
    bindUniformsCallback: (node) {
      _shader.setUniform('u_modelMat', node.getMatrix());
    },
  );
  Selector.drawSelectionOutline();

  web.window.requestAnimationFrame(frame.toJS);
}
