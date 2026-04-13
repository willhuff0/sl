import 'dart:js_interop';
import 'dart:typed_data';

import 'package:sl_engine/components/mesh_component.dart';
import 'package:sl_engine/gl/gl.dart';
import 'package:sl_engine/gl/render_texture.dart';
import 'package:sl_engine/gl/shader.dart';
import 'package:sl_engine/gl/sl.dart';
import 'package:sl_engine/node.dart';
import 'package:sl_engine/utils/renderer.dart';
import 'package:vector_math/vector_math.dart';

class ModelPreviewGenerator {
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

    // calculate bounding box

    final viewPos = Vector3(2.0, 2.0, 2.0);
    final viewMat = makeViewMatrix(viewPos, Vector3.zero(), Vector3(0.0, 1.0, 0.0));
    final projMat = makePerspectiveMatrix(radians(60.0), 1.0, 0.1, 4.0);
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

    final pixels = JSUint8Array.withLength(size * size * 4);
    gl.readPixels(0, 0, size, size, GL.RGBA, GL.UNSIGNED_BYTE, pixels);
    final dartPixels = pixels.toDart;

    _outputTexture.unbindFramebuffer();
    gl.viewport(0, 0, canvas.width, canvas.height);
    gl.clearColor(0.0, 0.0, 0.0, 1.0);

    return dartPixels;
  }
}
