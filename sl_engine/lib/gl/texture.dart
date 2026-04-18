import 'dart:js_interop';
import 'dart:typed_data';

import 'package:sl_engine/gl/gl.dart';
import 'package:sl_engine/logger.dart';
import 'package:web/web.dart' as web;

abstract interface class Texture {
  void bind(int slot);
}

class ImageTexture implements Texture {
  final Image image;

  final int magFilter;
  final int minFilter;
  final int wrapS;
  final int wrapT;

  ImageTexture({
    required this.image,
    this.magFilter = GL.LINEAR,
    this.minFilter = GL.LINEAR_MIPMAP_LINEAR,
    this.wrapS = GL.REPEAT,
    this.wrapT = GL.REPEAT,
  });

  @override
  void bind(int slot) {
    image.bind(slot);
    gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, magFilter);
    gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, minFilter);
    gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, wrapS);
    gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, wrapT);
  }
}

class Image {
  late final web.WebGLTexture _texture;

  Image() {
    _texture = gl.createTexture()!;
    gl.bindTexture(GL.TEXTURE_2D, _texture);
    gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR);
    gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR_MIPMAP_LINEAR);
    gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.REPEAT);
    gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.REPEAT);
  }

  static Future<Image?> loadFromMemory(Uint8List bytes, {String? name}) async {
    try {
      final blob = web.Blob([bytes.toJS].toJS);
      final bitmap = await web.window.createImageBitmap(blob).toDart;
      final result = Image();
      result.writeBitmap(bitmap);
      return result;
    } catch (e) {
      Logger.log('Failed to load image: $e');
      return null;
    }
  }

  void bind(int slot) {
    gl.activeTexture(GL.TEXTURE0 + slot);
    gl.bindTexture(GL.TEXTURE_2D, _texture);
  }

  void write(JSAny data, int format, int width, int height) {
    gl.bindTexture(GL.TEXTURE_2D, _texture);
    gl.texImage2D(GL.TEXTURE_2D, 0, format, width.toJS, height.toJS, 0.toJS, format, GL.UNSIGNED_BYTE, data);
    gl.generateMipmap(GL.TEXTURE_2D);
  }

  void writeBitmap(web.ImageBitmap bitmap) {
    gl.bindTexture(GL.TEXTURE_2D, _texture);
    gl.texImage2D(GL.TEXTURE_2D, 0, GL.RGBA, GL.RGBA.toJS, GL.UNSIGNED_BYTE.toJS, bitmap);
    gl.generateMipmap(GL.TEXTURE_2D);
  }
}
