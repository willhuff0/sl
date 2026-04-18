import 'dart:js_interop';

import 'package:sl_engine/gl/gl.dart';
import 'package:web/web.dart';

class Buffer {
  late final WebGLBuffer _buffer;

  final int type;

  Buffer([this.type = GL.ARRAY_BUFFER]) {
    _buffer = gl.createBuffer()!;
  }

  void bind() {
    gl.bindBuffer(type, _buffer);
  }

  void bindToUniformBuffer(int index) {
    gl.bindBufferBase(GL.UNIFORM_BUFFER, index, _buffer);
  }

  void unbind() {
    gl.bindBuffer(type, null);
  }

  void write(JSAny data, int usage, [int? srcOffset, int? length]) {
    if (length != null) {
      gl.bufferData(type, data, usage, srcOffset ?? 0, length);
    } else if (srcOffset != null) {
      gl.bufferData(type, data, usage, srcOffset);
    } else {
      gl.bufferData(type, data, usage);
    }
  }
}
