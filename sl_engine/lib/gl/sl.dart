import 'dart:js_interop';
import 'dart:typed_data';

import 'package:sl_engine/gl/buffer.dart';
import 'package:sl_engine/gl/gl.dart';
import 'package:vector_math/vector_math.dart';

class SLUniforms {
  final Matrix4 viewProjMat;
  final Matrix4 viewMat;
  final Vector3 viewPos;

  SLUniforms({
    required this.viewProjMat,
    required this.viewMat,
    required this.viewPos,
  });

  JSAny toJS() {
    final builder = BytesBuilder();

    builder.add(viewProjMat.storage.buffer.asUint8List());
    builder.add(viewMat.storage.buffer.asUint8List());
    builder.add(viewPos.storage.buffer.asUint8List());

    return builder.toBytes().toJS;
  }
}

class SL {
  static late final Buffer _buffer;

  static void init() {
    _buffer = Buffer(GL.UNIFORM_BUFFER);
    _buffer.bind();
    _buffer.bindToUniformBuffer(0);
  }

  static void setUniforms(SLUniforms uniforms) {
    _buffer.bind();
    _buffer.write(uniforms.toJS(), GL.DYNAMIC_DRAW);
  }
}
