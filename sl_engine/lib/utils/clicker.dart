import 'dart:js_interop';
import 'dart:math';

import 'package:sl_engine/gl/gl.dart';
import 'package:sl_engine/gl/render_texture.dart';
import 'package:sl_engine/gl/shader.dart';
import 'package:sl_engine/node.dart';
import 'package:sl_engine/utils/renderer.dart';

Vector3Int _convertIndexToId(int id) {
  return ((id ~/ 65536) % 256, (id ~/ 256) % 256, id % 256);
}

class Clicker {
  late final Shader _uniqueShader;

  late final RenderTexture _renderTexture;

  Clicker._();
  static Future<Clicker> create() async {
    final clicker = Clicker._();

    clicker._uniqueShader = (await Shader.load('shaders/clicker/unique'))!;

    clicker._renderTexture = RenderTexture(
      internalFormat: GL.RGBA8,
      format: GL.RGBA,
      type: GL.UNSIGNED_BYTE,
      depthFormat: GL.DEPTH_COMPONENT24,
    );

    return clicker;
  }

  void canvasSizeChanged(int width, int height) {
    _renderTexture.resize(width, height);
  }

  Node? click(int x, int y) {
    _uniqueShader.bind();

    _renderTexture.bindFramebuffer();
    gl.disable(GL.BLEND);
    gl.viewport(0, 0, canvas.width, canvas.height);
    gl.clearColor(0.0, 0.0, 0.0, 1.0);
    gl.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT);

    final Map<Vector3Int, Node> idToNode = {};
    var i = 1;
    Renderer.renderWithCustomShader(
      bindUniformsCallback: (node) {
        final id = _convertIndexToId(i++);
        idToNode[id] = node;

        _uniqueShader.setUniform('u_modelMat', node.getMatrix());
        _uniqueShader.setUniform('u_id', id);
      },
    );

    final pixels = JSUint8Array.withLength(4);
    gl.readPixels(x, canvas.height - y, 1, 1, GL.RGBA, GL.UNSIGNED_BYTE, pixels);
    final dartPixels = pixels.toDart;
    final id = (dartPixels[0], dartPixels[1], dartPixels[2]);

    print('x $x, y $y');
    print((dartPixels[0], dartPixels[1], dartPixels[2], dartPixels[3]));

    _renderTexture.unbindFramebuffer();
    print('width ${canvas.width}, height: ${canvas.height}');
    gl.viewport(0, 0, canvas.width, canvas.height);
    gl.enable(GL.BLEND);

    return idToNode[id];
  }
}
