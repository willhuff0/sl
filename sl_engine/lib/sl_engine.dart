import 'dart:js_interop';
import 'dart:math';
import 'dart:typed_data';

import 'package:sl_engine/gl/gl.dart';
import 'package:sl_engine/gl/mesh.dart';
import 'package:sl_engine/gl/shader.dart';
import 'package:sl_engine/node.dart';
import 'package:sl_engine/utils/clicker.dart';
import 'package:sl_engine/utils/outliner.dart';
import 'package:sl_engine/gl/sl.dart';
import 'package:sl_engine/utils/renderer.dart';
import 'package:vector_math/vector_math.dart';
import 'package:web/web.dart' as web;

late final List<Node> _cubes;
late final Outliner _outliner;
late final Clicker _clicker;

late final Shader _shader;

Node? _selected;

void initialize(web.HTMLCanvasElement canvas_) async {
  initGl(canvas_);
  SL.init();

  _outliner = await Outliner.create();
  _outliner.canvasSizeChanged(canvas.width, canvas.height);

  _clicker = await Clicker.create();
  _clicker.canvasSizeChanged(canvas.width, canvas.height);

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
      return node;
    },
  );

  _shader = (await Shader.load('shaders/test'))!;

  canvas.onClick.listen((event) {
    _selected = _clicker.click(event.clientX, event.clientY);
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

    _outliner.canvasSizeChanged(width, height);
    _clicker.canvasSizeChanged(canvas.width, canvas.height);
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
  if (_selected != null) _outliner.render(Renderer.getNodeMeshes(_selected!).first, _selected!.getMatrix(), Vector4(1.0, 0.7, 0.0, 1.0));

  web.window.requestAnimationFrame(frame.toJS);
}
