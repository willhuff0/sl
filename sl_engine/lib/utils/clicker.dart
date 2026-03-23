import 'dart:js_interop';

import 'package:sl_engine/gl/gl.dart';
import 'package:sl_engine/gl/render_texture.dart';
import 'package:sl_engine/gl/shader.dart';
import 'package:sl_engine/node.dart';
import 'package:sl_engine/utils/renderer.dart';

Vector3Int _convertIndexToColor(int index) {
  return ((index ~/ 65536) % 256, (index ~/ 256) % 256, index % 256);
}

int _convertColorToIndex(Vector3Int color) {
  return color.$1 * 65536 + color.$2 * 256 + color.$3;
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

    final Map<Vector3Int, Node> colorToNode = {};
    var i = 1;
    Renderer.renderAllCustomShader(
      bindUniformsCallback: (node) {
        final color = _convertIndexToColor(i++);
        colorToNode[color] = node;

        _uniqueShader.setUniform('u_modelMat', node.getMatrix());
        _uniqueShader.setUniform('u_color', color);
      },
    );

    final jsPixels = JSUint8Array.withLength(4);
    gl.readPixels(x, y, 1, 1, GL.RGBA, GL.UNSIGNED_BYTE, jsPixels);
    final pixels = jsPixels.toDart;
    final color = (pixels[0], pixels[1], pixels[2]);

    _renderTexture.unbindFramebuffer();
    gl.viewport(0, 0, canvas.width, canvas.height);
    gl.enable(GL.BLEND);

    return colorToNode[color];
  }

  Set<Node> overlap(int startX, int startY, int width, int height) {
    _uniqueShader.bind();

    _renderTexture.bindFramebuffer();
    gl.disable(GL.BLEND);
    gl.viewport(0, 0, canvas.width, canvas.height);
    gl.clearColor(0.0, 0.0, 0.0, 1.0);
    gl.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT);

    final Map<int, Node> indexToNode = {};
    var i = 1;
    Renderer.renderAllCustomShader(
      bindUniformsCallback: (node) {
        indexToNode[i] = node;
        final color = _convertIndexToColor(i++);

        _uniqueShader.setUniform('u_modelMat', node.getMatrix());
        _uniqueShader.setUniform('u_color', color);
      },
    );

    final jsPixels = JSUint8Array.withLength(width * height * 4);
    gl.readPixels(startX, startY, width, height, GL.RGBA, GL.UNSIGNED_BYTE, jsPixels);
    final pixels = jsPixels.toDart;

    final indices = <int>{};
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final startIndex = (y * width + x) * 4;
        final color = (
          pixels[startIndex + 0],
          pixels[startIndex + 1],
          pixels[startIndex + 2],
        );
        if (color.$1 == 0 && color.$2 == 0 && color.$3 == 0) continue;
        indices.add(_convertColorToIndex(color));
      }
    }

    _renderTexture.unbindFramebuffer();
    gl.viewport(0, 0, canvas.width, canvas.height);
    gl.enable(GL.BLEND);

    return indices.map((index) => indexToNode[index]!).toSet();
  }

  Node? clickUnregisteredNodes(int x, int y, Iterable<Node> roots) {
    _uniqueShader.bind();

    _renderTexture.bindFramebuffer();
    gl.disable(GL.BLEND);
    gl.viewport(0, 0, canvas.width, canvas.height);
    gl.clearColor(0.0, 0.0, 0.0, 1.0);
    gl.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT);

    final Map<Vector3Int, Node> colorToNode = {};
    var i = 1;
    for (final root in roots) {
      Renderer.renderUnregisteredNodeCustomShader(
        root,
        bindUniformsCallback: (node) {
          final color = _convertIndexToColor(i++);
          colorToNode[color] = node;

          _uniqueShader.setUniform('u_modelMat', node.getMatrix());
          _uniqueShader.setUniform('u_color', color);
        },
      );
    }

    final pixels = JSUint8Array.withLength(4);
    gl.readPixels(x, canvas.height - y, 1, 1, GL.RGBA, GL.UNSIGNED_BYTE, pixels);
    final dartPixels = pixels.toDart;
    final color = (dartPixels[0], dartPixels[1], dartPixels[2]);

    _renderTexture.unbindFramebuffer();
    gl.viewport(0, 0, canvas.width, canvas.height);
    gl.enable(GL.BLEND);

    return colorToNode[color];
  }
}
