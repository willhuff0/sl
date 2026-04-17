import 'dart:js_interop';

import 'package:sl_engine/gl/gl.dart';
import 'package:sl_engine/logger.dart';
import 'package:web/web.dart';

class RenderTexture {
  WebGLTexture? _texture;
  WebGLRenderbuffer? _depthBuffer;
  WebGLFramebuffer? _framebuffer;

  final int internalFormat;
  final int format;
  final int type;
  final int? depthFormat;

  RenderTexture({
    this.internalFormat = GL.RGBA16F,
    this.format = GL.RGBA,
    this.type = GL.FLOAT,
    this.depthFormat,
  });

  void resize(int width, int height) {
    if (_framebuffer != null) gl.deleteFramebuffer(_framebuffer);
    if (_texture != null) gl.deleteTexture(_texture);
    if (_depthBuffer != null) gl.deleteRenderbuffer(_depthBuffer);

    _framebuffer = gl.createFramebuffer()!;
    gl.bindFramebuffer(GL.FRAMEBUFFER, _framebuffer);

    _texture = gl.createTexture()!;
    gl.activeTexture(GL.TEXTURE0);
    gl.bindTexture(GL.TEXTURE_2D, _texture);
    gl.texImage2D(GL.TEXTURE_2D, 0, internalFormat, width.toJS, height.toJS, 0.toJS, format, type, null);
    gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR);
    gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE);
    gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE);
    gl.framebufferTexture2D(GL.FRAMEBUFFER, GL.COLOR_ATTACHMENT0, GL.TEXTURE_2D, _texture, 0);

    if (depthFormat != null) {
      _depthBuffer = gl.createRenderbuffer()!;
      gl.bindRenderbuffer(GL.RENDERBUFFER, _depthBuffer);
      gl.renderbufferStorage(GL.RENDERBUFFER, depthFormat!, width, height);
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

    gl.bindFramebuffer(GL.FRAMEBUFFER, null);
    gl.viewport(0, 0, canvas.width, canvas.height);
  }

  void bindFramebuffer() {
    gl.bindFramebuffer(GL.FRAMEBUFFER, _framebuffer);
  }

  void unbindFramebuffer() {
    gl.bindFramebuffer(GL.FRAMEBUFFER, defaultFramebuffer);
  }

  void bindTexture(GLenum slot) {
    gl.activeTexture(slot);
    gl.bindTexture(GL.TEXTURE_2D, _texture);
  }

  void unbindTexture(GLenum slot) {
    gl.activeTexture(slot);
    gl.bindTexture(GL.TEXTURE_2D, null);
  }

  WebGLTexture getTexture() => _texture!;
  WebGLRenderbuffer? getDepthBuffer() => _depthBuffer;
  WebGLFramebuffer getFramebuffer() => _framebuffer!;
}
