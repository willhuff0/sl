import 'dart:async';

import 'package:sl_engine/gl/gl.dart';
import 'package:sl_engine/gl/gltf.dart';
import 'package:sl_engine/gl/render_texture.dart';
import 'package:sl_engine/gl/shader.dart';
import 'package:sl_engine/node.dart';
import 'package:sl_engine/editor/gizmos/gizmo.dart';
import 'package:sl_engine/editor/gizmos/translation_gizmo.dart';
import 'package:sl_engine/editor/gizmos/rotation_gizmo.dart';
import 'package:sl_engine/editor/gizmos/scale_gizmo.dart';
import 'package:vector_math/vector_math.dart';

final _handleScale = Vector3(0.025, 0.025, 0.025);

class Handles {
  static var handleScreenProportion = 0.2;

  late final Shader _flatShader;
  late final Shader _blitShader;

  late final RenderTexture _renderTexture;

  late final Node _root;
  late final TranslationGizmo translationGizmo;
  late final RotationGizmo rotationGizmo;
  late final ScaleGizmo scaleGizmo;
  late Gizmo activeGizmo;

  Handles._();
  static Future<Handles> create() async {
    final handles = Handles._();

    handles._flatShader = (await Shader.load('shaders/handles/flat'))!;
    handles._blitShader = (await Shader.loadSeparate('shaders/fullscreen', 'shaders/handles/blit'))!;
    handles._renderTexture = RenderTexture(
      internalFormat: GL.RGBA8,
      format: GL.RGBA,
      type: GL.UNSIGNED_BYTE,
      depthFormat: GL.DEPTH_COMPONENT24,
    );
    handles._root = (await GLTF.load('models/Gizmo.glb'))!.root;

    handles.translationGizmo = TranslationGizmo()..init(handles._root);
    handles.rotationGizmo = RotationGizmo()..init(handles._root);
    handles.scaleGizmo = ScaleGizmo()..init(handles._root);
    handles.activeGizmo = handles.translationGizmo;

    handles._blitShader.bind();
    handles._blitShader.setUniform('u_texture', 0);

    handles._root.lScale = _handleScale;

    slCanvasSizeChanged.listen((size) => handles._canvasSizeChanged(size.$1, size.$2));
    handles._canvasSizeChanged(canvas.width, canvas.height);
    return handles;
  }

  void _canvasSizeChanged(int width, int height) {
    _renderTexture.resize(width, height);
  }

  void drawHandles(Vector3 position, Quaternion rotation) {
    _root.lPos = position;
    _root.lRot = rotation;

    _renderTexture.bindFramebuffer();
    gl.disable(GL.BLEND);
    gl.clearColor(0.0, 0.0, 0.0, 0.0);
    gl.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT);

    activeGizmo.draw(_flatShader, handleScreenProportion);

    _blitShader.bind();

    _renderTexture.unbindFramebuffer();
    gl.enable(GL.BLEND);
    gl.viewport(0, 0, canvas.width, canvas.height);
    _renderTexture.bindTexture(GL.TEXTURE0);
    gl.depthMask(false);
    gl.depthFunc(GL.ALWAYS);
    gl.drawArrays(GL.TRIANGLES, 0, 6);
    gl.depthFunc(GL.LEQUAL);
    gl.depthMask(true);
  }
}
