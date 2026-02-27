import 'package:sl_engine/gl/gl.dart';
import 'package:sl_engine/gl/render_texture.dart';
import 'package:sl_engine/gl/shader.dart';
import 'package:sl_engine/node.dart';
import 'package:sl_engine/utils/renderer.dart';
import 'package:vector_math/vector_math.dart';

class Outliner {
  late final Shader _flatShader;
  late final Shader _blurShader;
  late final Shader _blitShader;

  late final RenderTexture _unblurredRenderTexture;
  late final RenderTexture _blurredRenderTexture0;
  late final RenderTexture _blurredRenderTexture1;

  Outliner._();
  static Future<Outliner> create() async {
    final outliner = Outliner._();

    outliner._flatShader = (await Shader.load('shaders/outliner/flat'))!;
    outliner._blurShader = (await Shader.loadSeparate('shaders/fullscreen', 'shaders/outliner/blur'))!;
    outliner._blitShader = (await Shader.loadSeparate('shaders/fullscreen', 'shaders/outliner/blit'))!;

    outliner._blurShader.bind();
    outliner._blurShader.setUniform('u_inputTexture', 0);

    outliner._blitShader.bind();
    outliner._blitShader.setUniform('u_unblurredTexture', 0);
    outliner._blitShader.setUniform('u_blurredTexture', 1);

    outliner._unblurredRenderTexture = RenderTexture(
      internalFormat: GL.R8,
      format: GL.RED,
      type: GL.UNSIGNED_BYTE,
    );
    outliner._blurredRenderTexture0 = RenderTexture(
      internalFormat: GL.R8,
      format: GL.RED,
      type: GL.UNSIGNED_BYTE,
    );
    outliner._blurredRenderTexture1 = RenderTexture(
      internalFormat: GL.R8,
      format: GL.RED,
      type: GL.UNSIGNED_BYTE,
    );

    return outliner;
  }

  void canvasSizeChanged(int width, int height) {
    _unblurredRenderTexture.resize(width, height);
    _blurredRenderTexture0.resize(width, height);
    _blurredRenderTexture1.resize(width, height);
  }

  void render(Set<Node> nodes, Vector4 color) {
    // render flat
    _flatShader.bind();

    gl.disable(GL.BLEND);
    _unblurredRenderTexture.bindFramebuffer();
    gl.viewport(0, 0, canvas.width, canvas.height);
    gl.clearColor(0.0, 0.0, 0.0, 1.0);
    gl.clear(GL.COLOR_BUFFER_BIT);

    for (final root in nodes) {
      Renderer.drawNodeAndChildren(
        root,
        bindUniformsCallback: (node) {
          _flatShader.setUniform('u_modelMat', node.getMatrix());
        },
      );
    }

    // blur
    _blurShader.bind();

    _unblurredRenderTexture.bindTexture(GL.TEXTURE0);
    _blurredRenderTexture0.bindFramebuffer();
    gl.viewport(0, 0, canvas.width, canvas.height);
    gl.clear(GL.COLOR_BUFFER_BIT);
    _blurShader.setUniform('u_blurDirection', Vector2(1.0, 0.0));
    gl.drawArrays(GL.TRIANGLES, 0, 6);

    _blurredRenderTexture0.bindTexture(GL.TEXTURE0);
    _blurredRenderTexture1.bindFramebuffer();
    gl.viewport(0, 0, canvas.width, canvas.height);
    gl.clear(GL.COLOR_BUFFER_BIT);
    _blurShader.setUniform('u_blurDirection', Vector2(0.0, 1.0));
    gl.drawArrays(GL.TRIANGLES, 0, 6);

    // blit
    _blitShader.bind();
    _blitShader.setUniform('u_color', color);

    _blurredRenderTexture1.unbindFramebuffer();
    gl.enable(GL.BLEND);
    gl.blendFunc(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA);
    gl.viewport(0, 0, canvas.width, canvas.height);
    _unblurredRenderTexture.bindTexture(GL.TEXTURE0);
    _blurredRenderTexture1.bindTexture(GL.TEXTURE1);
    gl.depthMask(false);
    gl.depthFunc(GL.ALWAYS);
    gl.drawArrays(GL.TRIANGLES, 0, 6);
    gl.depthFunc(GL.LESS);
    gl.depthMask(true);
  }
}
