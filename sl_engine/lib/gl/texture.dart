import 'dart:js_interop';
import 'dart:typed_data';

import 'package:sl_engine/gl/gl.dart';
import 'package:sl_engine/logger.dart';
import 'package:web/web.dart';
import 'package:image/image.dart' as img;

class Image {
  late final WebGLTexture _texture;

  Image() {
    _texture = gl.createTexture()!;
    gl.bindTexture(GL.TEXTURE_2D, _texture);
    gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR_MIPMAP_LINEAR);
    gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR_MIPMAP_LINEAR);
    gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.REPEAT);
    gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.REPEAT);
  }

  static int? _getFormatFromChannelCount(int channelCount) {
    return switch (channelCount) {
      3 => GL.RGB,
      4 => GL.RGBA,
      _ => null,
    };
  }

  static Image? loadFromMemory(Uint8List bytes, {String? name}) {
    img.Image? image;
    if (name != null) {
      image = img.decodeNamedImage(name, bytes);
    } else {
      image = img.decodeImage(bytes);
    }
    if (image == null) return null;

    final format = _getFormatFromChannelCount(image.numChannels);
    if (format == null) {
      Logger.log('Tried to load an image with an unsupported channel count ${image.numChannels}. Only 3 or 4 channel images are supported.');
      return null;
    }

    final result = Image();
    result.write(image.getBytes(order: img.ChannelOrder.rgba).toJS, format, image.width, image.height);
    return result;
  }

  void bind(int slot) {
    gl.activeTexture(GL.TEXTURE0 + slot);
    gl.bindTexture(GL.TEXTURE, _texture);
  }

  void write(JSAny data, int format, int width, int height) {
    gl.texImage2D(GL.TEXTURE_2D, 0, format, width.toJS, height.toJS, 0.toJS, format, GL.UNSIGNED_BYTE, data);
  }
}

class Texture {
  final Image image;

  final int magFilter;
  final int minFilter;
  final int wrapS;
  final int wrapT;

  Texture({
    required this.image,
    this.magFilter = GL.LINEAR_MIPMAP_LINEAR,
    this.minFilter = GL.LINEAR_MIPMAP_LINEAR,
    this.wrapS = GL.REPEAT,
    this.wrapT = GL.REPEAT,
  });

  void bind(int slot) {
    image.bind(slot);
    gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, magFilter);
    gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, minFilter);
    gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, wrapS);
    gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, wrapT);
  }
}
