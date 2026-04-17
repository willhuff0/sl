import 'package:sl_engine/gl/gl.dart';
import 'package:sl_engine/gl/shader.dart';
import 'package:web/web.dart' as web;

class BrdfLut {
  final web.WebGLTexture texture;

  BrdfLut._({required this.texture});

  static Shader? _brdfLutShader;
  static web.WebGLFramebuffer? _framebuffer;
  static Future<BrdfLut> generate({int size = 512}) async {
    _brdfLutShader ??= (await Shader.loadSeparate('shaders/fullscreen', 'shaders/brdf_lut/brdf_lut'))!;
    _brdfLutShader!.bind();

    final brdfLut = gl.createTexture()!;
    gl.activeTexture(GL.TEXTURE0);
    gl.bindTexture(GL.TEXTURE_2D, brdfLut);
    gl.texStorage2D(GL.TEXTURE_2D, 1, GL.RG16F, size, size);
    gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE);
    gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE);
    gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR);
    gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR);

    _framebuffer ??= gl.createFramebuffer()!;
    gl.bindFramebuffer(GL.FRAMEBUFFER, _framebuffer);
    gl.framebufferTexture2D(GL.FRAMEBUFFER, GL.COLOR_ATTACHMENT0, GL.TEXTURE_2D, brdfLut, 0);

    gl.viewport(0, 0, size, size);
    gl.clearColor(0.0, 0.0, 0.0, 1.0);
    gl.clear(GL.COLOR_BUFFER_BIT);
    gl.drawArrays(GL.TRIANGLES, 0, 6);

    gl.bindFramebuffer(GL.FRAMEBUFFER, null);
    return BrdfLut._(texture: brdfLut);
  }
}
