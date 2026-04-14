import 'dart:js_interop';
import 'dart:math';
import 'dart:typed_data';

import 'package:sl_engine/gl/gl.dart';
import 'package:sl_engine/gl/render_texture.dart';
import 'package:sl_engine/gl/shader.dart';
import 'package:sl_engine/gl/sl.dart';
import 'package:sl_engine/node.dart';
import 'package:sl_engine/utils/bounds.dart';
import 'package:sl_engine/utils/renderer.dart';
import 'package:vector_math/vector_math.dart';

class ModelPreviewGenerator {
  static const _fov = 60.0;
  static const _distancePadding = 1.15;

  late final Shader _previewShader;

  late final RenderTexture _outputTexture;

  ModelPreviewGenerator._();
  static Future<ModelPreviewGenerator> create() async {
    final previewGenerator = ModelPreviewGenerator._();

    previewGenerator._previewShader = (await Shader.load('shaders/preview/preview'))!;

    previewGenerator._outputTexture = RenderTexture(
      internalFormat: GL.RGBA8,
      format: GL.RGBA,
      type: GL.UNSIGNED_BYTE,
      depthFormat: GL.DEPTH_COMPONENT24,
    );

    return previewGenerator;
  }

  Uint8List generateModelPreview(Node node, {int size = 128}) {
    _outputTexture.resize(size, size);

    _previewShader.bind();
    _outputTexture.bindFramebuffer();
    gl.viewport(0, 0, size, size);
    gl.clearColor(0.0, 0.0, 0.0, 0.0);
    gl.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT);
    gl.blendFunc(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA);

    final bounds = Bounds.computeBounds(node);

    final center = bounds.center;

    final radius = ((bounds.max - bounds.min) * 0.5).length;
    final distance = (radius / tan(radians(_fov) * 0.5)) * _distancePadding;

    final viewDir = Vector3(-1.0, -0.8, -1.0)..normalize();
    final viewPos = center - viewDir * distance;

    final viewMat = makeViewMatrix(
      viewPos,
      center,
      Vector3(0.0, 1.0, 0.0),
    );
    final projMat = makePerspectiveMatrix(
      radians(_fov),
      1.0,
      max(0.01, distance - radius * 2.0), // near
      distance + radius * 2.0, //            far
    );
    SL.setUniforms(
      SLUniforms(
        viewProjMat: projMat * viewMat,
        viewMat: viewMat,
        viewPos: viewPos,
      ),
    );
    Renderer.renderUnregisteredNodeCustomShader(
      node,
      bindUniformsCallback: (node) {
        _previewShader.setUniform('u_modelMat', node.getMatrix());
        _previewShader.setUniform('u_normalMat', node.getMatrix().getNormalMatrix());
      },
    );

    node.enterScene();

    final pixels = JSUint8Array.withLength(size * size * 4);
    gl.readPixels(0, 0, size, size, GL.RGBA, GL.UNSIGNED_BYTE, pixels);
    final dartPixels = pixels.toDart;

    _outputTexture.unbindFramebuffer();
    gl.viewport(0, 0, canvas.width, canvas.height);
    gl.clearColor(0.0, 0.0, 0.0, 1.0);

    return dartPixels;
  }
}
