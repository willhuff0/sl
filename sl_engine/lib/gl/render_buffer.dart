import 'package:sl_engine/gl/gl.dart';
import 'package:sl_engine/logger.dart';
import 'package:web/web.dart';

class RenderBuffer {
  WebGLRenderbuffer? _colorBuffer;
  WebGLRenderbuffer? _depthBuffer;
  WebGLFramebuffer? _framebuffer;

  final int sampleCount;
  final int colorFormat;
  final int? depthFormat;

  RenderBuffer({
    this.sampleCount = 0,
    this.colorFormat = GL.RGBA16F,
    this.depthFormat,
  });

  void resize(int width, int height) {
    if (_framebuffer != null) gl.deleteFramebuffer(_framebuffer);
    if (_colorBuffer != null) gl.deleteRenderbuffer(_colorBuffer);
    if (_depthBuffer != null) gl.deleteRenderbuffer(_depthBuffer);

    _framebuffer = gl.createFramebuffer()!;
    gl.bindFramebuffer(GL.FRAMEBUFFER, _framebuffer);

    _colorBuffer = gl.createRenderbuffer()!;
    gl.bindRenderbuffer(GL.RENDERBUFFER, _colorBuffer);
    if (sampleCount != 0) {
      gl.renderbufferStorageMultisample(GL.RENDERBUFFER, sampleCount, colorFormat, width, height);
    } else {
      gl.renderbufferStorage(GL.RENDERBUFFER, colorFormat, width, height);
    }
    gl.framebufferRenderbuffer(GL.FRAMEBUFFER, GL.COLOR_ATTACHMENT0, GL.RENDERBUFFER, _colorBuffer);

    if (depthFormat != null) {
      _depthBuffer = gl.createRenderbuffer()!;
      gl.bindRenderbuffer(GL.RENDERBUFFER, _depthBuffer);
      if (sampleCount != 0) {
        gl.renderbufferStorageMultisample(GL.RENDERBUFFER, sampleCount, depthFormat!, width, height);
      } else {
        gl.renderbufferStorage(GL.RENDERBUFFER, depthFormat!, width, height);
      }
      gl.framebufferRenderbuffer(GL.FRAMEBUFFER, GL.DEPTH_ATTACHMENT, GL.RENDERBUFFER, _depthBuffer);
    }

    switch (gl.checkFramebufferStatus(GL.FRAMEBUFFER)) {
      case GL.FRAMEBUFFER_COMPLETE:
        break;
      case GL.FRAMEBUFFER_INCOMPLETE_ATTACHMENT:
        Logger.log('Framebuffer Incomplete Attachment: The attachment types are mismatched or not all framebuffer attachment points are framebuffer attachment complete.', .warning);
        break;
      case GL.FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT:
        Logger.log('Framebuffer Incomplete Missing Attachment: There is no attachment.', .warning);
        break;
      case GL.FRAMEBUFFER_INCOMPLETE_DIMENSIONS:
        Logger.log('Framebuffer Incomplete Dimensions: Height and width of the attachment are not the same.', .warning);
        break;
      case GL.FRAMEBUFFER_UNSUPPORTED:
        Logger.log('Framebuffer Unsupported: The format of the attachment is not supported or if depth and stencil attachments are not the same renderbuffer.', .warning);
        break;
      case GL.FRAMEBUFFER_INCOMPLETE_MULTISAMPLE:
        Logger.log('Framebuffer Incomplete Multisample: The values of gl.RENDERBUFFER_SAMPLES are different among attached renderbuffers, or are non-zero if the attached images are a mix of renderbuffers and textures.', .warning);
        break;
    }

    gl.bindFramebuffer(GL.FRAMEBUFFER, defaultFramebuffer);
    gl.viewport(0, 0, canvas.width, canvas.height);
  }

  void bindFramebuffer() {
    gl.bindFramebuffer(GL.FRAMEBUFFER, _framebuffer);
  }

  void unbindFramebuffer() {
    gl.bindFramebuffer(GL.FRAMEBUFFER, defaultFramebuffer);
  }

  WebGLRenderbuffer getColorBuffer() => _colorBuffer!;
  WebGLRenderbuffer? getDepthBuffer() => _depthBuffer;
  WebGLFramebuffer getFramebuffer() => _framebuffer!;
}
