// import 'dart:js_interop';

// import 'package:sl_engine/gl/gl.dart';
// import 'package:sl_engine/gl/shader.dart';
// import 'package:web/web.dart' as web;

// class HDRI {
//   final web.WebGLTexture texture;
//   final Vector2Int size;
// }

// class CubeMap {
//   late final web.WebGLTexture _texture;
// }

// class CubeMapConverter {
//   static CubeMap convertHdriToCubeMap(HDRI hdri) {
//     final faceSize = hdri.size.$2;

//     final cubeMap = gl.createTexture();
//     gl.bindTexture(GL.TEXTURE_CUBE_MAP, cubeMap);
//     for (var i = 0; i < 6; i++) {
//       gl.texImage2D(GL.TEXTURE_CUBE_MAP_POSITIVE_X + i, 0, GL.RGB16F, faceSize.toJS, faceSize.toJS, 0.toJS, GL.RGB, GL.HALF_FLOAT, null);
//     }
//     gl.texParameteri(GL.TEXTURE_CUBE_MAP, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE);
//     gl.texParameteri(GL.TEXTURE_CUBE_MAP, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE);
//     gl.texParameteri(GL.TEXTURE_CUBE_MAP, GL.TEXTURE_WRAP_R, GL.CLAMP_TO_EDGE);
//     gl.texParameteri(GL.TEXTURE_CUBE_MAP, GL.TEXTURE_MIN_FILTER, GL.LINEAR);
//     gl.texParameteri(GL.TEXTURE_CUBE_MAP, GL.TEXTURE_MAG_FILTER, GL.LINEAR);
//   }
// }

// class Skybox {}
