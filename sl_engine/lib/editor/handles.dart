import 'package:sl_engine/gl/gl.dart';
import 'package:sl_engine/gl/gltf.dart';
import 'package:sl_engine/gl/render_texture.dart';
import 'package:sl_engine/gl/shader.dart';
import 'package:sl_engine/node.dart';
import 'package:sl_engine/utils/renderer.dart';
import 'package:vector_math/vector_math.dart';

final _handleScale = Vector3(0.025, 0.025, 0.025);
final _handleScreenProportion = 0.1;

final _forwardHandleColor = Vector4(0.0, 0.0, 1.0, 1.0);
final _rightHandleColor = Vector4(1.0, 0.0, 0.0, 1.0);
final _upHandleColor = Vector4(0.0, 1.0, 0.0, 1.0);
final _notDraggedHandleBrightness = 0.6;
final _notDraggedHandleOpacity = 0.8;

Vector4 _getHandleColor(Vector4 baseColor, Node handle, Node? draggedHandle) {
  if (draggedHandle == null || draggedHandle == handle) {
    return baseColor;
  } else {
    return Vector4(baseColor.x * _notDraggedHandleBrightness, baseColor.y * _notDraggedHandleBrightness, baseColor.z * _notDraggedHandleBrightness, baseColor.a * _notDraggedHandleOpacity);
  }
}

class Handles {
  late final Shader _flatShader;
  late final Shader _blitShader;

  late final RenderTexture _renderTexture;

  late final Node _root;
  late final Node _forwardHandle;
  late final Node _rightHandle;
  late final Node _upHandle;
  late final Node _xyPlane;
  late final Node _yzPlane;
  late final Node _xzPlane;

  Handles._();
  static Future<Handles> create() async {
    final handles = Handles._();

    handles._flatShader = (await Shader.load('shaders/handles/flat'))!;
    handles._blitShader = (await Shader.loadSeparate('shaders/fullscreen', 'shaders/handles/blit'))!;
    handles._renderTexture = RenderTexture(
      internalFormat: GL.RGBA8,
      format: GL.RGBA,
      type: GL.UNSIGNED_BYTE,
      depthFormat: GL.DEPTH_COMPONENT24,
    );
    handles._root = (await GLTF.load('models/arrow.glb'))!.root;
    handles._forwardHandle = handles._root.children[0];
    handles._rightHandle = handles._root.children[1];
    handles._upHandle = handles._root.children[2];

    handles._blitShader.bind();
    handles._blitShader.setUniform('u_texture', 0);

    handles._root.lScale = _handleScale;

    return handles;
  }

  void canvasSizeChanged(int width, int height) {
    _renderTexture.resize(width, height);
  }

  (Node forward, Node right, Node up) getHandles(Vector3 position, Quaternion rotation) {
    _root.lPos = position;
    _root.lRot = rotation;
    return (_forwardHandle, _rightHandle, _upHandle);
  }

  Vector3 getHandleDirection(Node node, Node handle) {
    if (handle == _forwardHandle) {
      return node.getForwardVector();
    } else if (handle == _rightHandle) {
      return node.getRightVector();
    } else if (handle == _upHandle) {
      return node.getUpVector();
    }
    return Vector3.zero();
  }

  void drawHandles(Vector3 position, Quaternion rotation, Node? draggedHandle) {
    _root.lPos = position;
    _root.lRot = rotation;

    _renderTexture.bindFramebuffer();
    gl.disable(GL.BLEND);
    gl.clearColor(0.0, 0.0, 0.0, 0.0);
    gl.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT);

    _flatShader.bind();
    _flatShader.setUniform('u_screenScale', _handleScreenProportion);

    Renderer.renderUnregisteredNodeCustomShader(
      _forwardHandle,
      bindUniformsCallback: (node) {
        _flatShader.setUniform('u_color', _getHandleColor(_forwardHandleColor, _forwardHandle, draggedHandle));
        _flatShader.setUniform('u_modelMat', node.getMatrix());
      },
    );
    Renderer.renderUnregisteredNodeCustomShader(
      _rightHandle,
      bindUniformsCallback: (node) {
        _flatShader.setUniform('u_color', _getHandleColor(_rightHandleColor, _rightHandle, draggedHandle));
        _flatShader.setUniform('u_modelMat', node.getMatrix());
      },
    );
    Renderer.renderUnregisteredNodeCustomShader(
      _upHandle,
      bindUniformsCallback: (node) {
        _flatShader.setUniform('u_color', _getHandleColor(_upHandleColor, _upHandle, draggedHandle));
        _flatShader.setUniform('u_modelMat', node.getMatrix());
      },
    );

    _blitShader.bind();

    _renderTexture.unbindFramebuffer();
    gl.enable(GL.BLEND);
    gl.viewport(0, 0, canvas.width, canvas.height);
    _renderTexture.bindTexture(GL.TEXTURE0);
    gl.depthMask(false);
    gl.depthFunc(GL.ALWAYS);
    gl.drawArrays(GL.TRIANGLES, 0, 6);
    gl.depthFunc(GL.LESS);
    gl.depthMask(true);
  }
}
