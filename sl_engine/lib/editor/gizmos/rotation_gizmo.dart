import 'package:sl_engine/editor/gizmos/gizmo.dart';
import 'package:sl_engine/editor/handles.dart';
import 'package:sl_engine/node.dart';
import 'package:sl_engine/gl/shader.dart';
import 'package:sl_engine/gl/gl.dart';
import 'package:sl_engine/editor/fly_camera.dart';
import 'package:sl_engine/utils/clicker.dart';
import 'package:sl_engine/utils/renderer.dart';
import 'package:vector_math/vector_math.dart';

class RotationGizmo extends Gizmo {
  late final Node _zHandle;
  late final Node _xHandle;
  late final Node _yHandle;

  final Vector4 _forwardHandleColor = Vector4(0.0, 0.0, 1.0, 1.0);
  final Vector4 _rightHandleColor = Vector4(1.0, 0.0, 0.0, 1.0);
  final Vector4 _upHandleColor = Vector4(0.0, 1.0, 0.0, 1.0);
  final double _notDraggedHandleBrightness = 0.6;
  final double _notDraggedHandleOpacity = 0.8;

  Node? _draggedHandle;
  Vector2? _dragStartMouse;
  Quaternion? _initialRot;
  Vector2? _screenTangent;
  Vector3? _initialAxis;

  final Map<Node, Node> _clickToVisual = {};

  @override
  void init(Node root) {
    _zHandle = root.children.firstWhere((child) => child.name == '0_Z_Rot');
    _clickToVisual[root.children.firstWhere((child) => child.name == '0_Z_Rot_ClickTarget')] = _zHandle;

    _xHandle = root.children.firstWhere((child) => child.name == '1_X_Rot');
    _clickToVisual[root.children.firstWhere((child) => child.name == '1_X_Rot_ClickTarget')] = _xHandle;

    _yHandle = root.children.firstWhere((child) => child.name == '2_Y_Rot');
    _clickToVisual[root.children.firstWhere((child) => child.name == '2_Y_Rot_ClickTarget')] = _yHandle;
  }

  @override
  List<Node> getHandles() {
    return _clickToVisual.keys.toList();
  }

  Vector3 _getHandleAxis(Node node, Node handle) {
    if (handle == _zHandle) {
      return node.getForwardVector();
    } else if (handle == _xHandle) {
      return node.getRightVector();
    } else if (handle == _yHandle) {
      return node.getUpVector();
    }
    return Vector3.zero();
  }

  Vector3? _linePlaneIntersection(Vector3 linePoint, Vector3 lineDirection, Vector3 planePoint, Vector3 planeNormal) {
    final denominator = lineDirection.dot(planeNormal);
    if (denominator.abs() < 0.000001) return null;
    final t = (planePoint - linePoint).dot(planeNormal) / denominator;
    return linePoint + lineDirection * t;
  }

  Vector3 _getCameraRayDirection(Vector2Int mousePosition, Vector2Int windowSize, Matrix4 projMat, Matrix4 viewMat) {
    final x = (2.0 * mousePosition.$1) / windowSize.$1 - 1.0;
    final y = 1.0 - (2.0 * mousePosition.$2) / windowSize.$2;

    final clipRay = Vector4(x, y, -1.0, 1.0);
    final eyeRay = (Matrix4.inverted(projMat) * clipRay) as Vector4;
    eyeRay.z = -1.0;
    eyeRay.w = 0.0;
    final worldRay = (Matrix4.inverted(viewMat) * eyeRay) as Vector4;
    return Vector3(worldRay.x, worldRay.y, worldRay.z)..normalize();
  }

  Vector2 _worldToScreen(Vector3 pos, Vector2Int windowSize, Matrix4 projMat, Matrix4 viewMat) {
    final clipVec = Vector4(pos.x, pos.y, pos.z, 1.0);
    final viewVec = viewMat * clipVec;
    final clip = projMat * viewVec;
    final ndc = Vector3(clip.x / clip.w, clip.y / clip.w, clip.z / clip.w);
    return Vector2(
      (ndc.x + 1.0) / 2.0 * windowSize.$1,
      (1.0 - ndc.y) / 2.0 * windowSize.$2,
    );
  }

  @override
  Node? onMouseDown(int x, int y, Node selectedNode, FlyCamera camera, Clicker clicker) {
    final clicked = clicker.clickUnregisteredNodes(x, y, getHandles(), screenScale: Handles.handleScreenProportion);
    _draggedHandle = clicked != null ? _clickToVisual[clicked] : null;

    if (_draggedHandle != null) {
      final state = camera.getState();
      if (state != null) {
        final (linePoint, viewMat, projMat) = state;
        final windowSize = (canvas.width, canvas.height);
        final lineDirection = _getCameraRayDirection((x, y), windowSize, projMat, viewMat);
        final axis = _getHandleAxis(selectedNode, _draggedHandle!);
        final planePoint = selectedNode.wPos;

        final intersection = _linePlaneIntersection(linePoint, lineDirection, planePoint, axis);
        if (intersection != null) {
          final radiusVector = intersection - planePoint;
          radiusVector.normalize();

          final tangent = axis.cross(radiusVector);
          tangent.normalize();

          final pScreen = _worldToScreen(intersection, windowSize, projMat, viewMat);
          final pTangentScreen = _worldToScreen(intersection + tangent, windowSize, projMat, viewMat);

          _screenTangent = pTangentScreen - pScreen;
          if (_screenTangent!.length2 > 0.0001) {
            _screenTangent!.normalize();
          } else {
            _screenTangent = Vector2(1.0, 0.0);
          }

          _dragStartMouse = Vector2(x.toDouble(), y.toDouble());
          _initialRot = selectedNode.wRot.clone();
          _initialAxis = axis;
        }
      }
    } else {
      _dragStartMouse = null;
      _initialRot = null;
      _screenTangent = null;
      _initialAxis = null;
    }
    return _draggedHandle;
  }

  @override
  void onMouseMove(int x, int y, Node selectedNode, FlyCamera camera) {
    if (_draggedHandle != null && _dragStartMouse != null && _initialRot != null && _screenTangent != null && _initialAxis != null) {
      final mouseCurrent = Vector2(x.toDouble(), y.toDouble());
      final mouseDelta = mouseCurrent - _dragStartMouse!;

      final movement = mouseDelta.dot(_screenTangent!);
      final sensitivity = 0.01;
      final angle = movement * sensitivity;

      final deltaRot = Quaternion.axisAngle(_initialAxis!, angle);
      selectedNode.wRot = deltaRot * _initialRot!;
    }
  }

  @override
  void onMouseUp() {
    _draggedHandle = null;
    _dragStartMouse = null;
    _initialRot = null;
    _screenTangent = null;
    _initialAxis = null;
  }

  Vector4 _getHandleColor(Vector4 baseColor, Node handle) {
    if (_draggedHandle == null || _draggedHandle == handle) {
      return baseColor;
    } else {
      return Vector4(baseColor.x * _notDraggedHandleBrightness, baseColor.y * _notDraggedHandleBrightness, baseColor.z * _notDraggedHandleBrightness, baseColor.a * _notDraggedHandleOpacity);
    }
  }

  @override
  void draw(Shader flatShader, double screenProportion) {
    flatShader.bind();
    flatShader.setUniform('u_screenScale', screenProportion);

    Renderer.renderUnregisteredNodeCustomShader(
      _zHandle,
      bindUniformsCallback: (node) {
        flatShader.setUniform('u_color', _getHandleColor(_forwardHandleColor, _zHandle));
        flatShader.setUniform('u_modelMat', node.getMatrix());
      },
    );
    Renderer.renderUnregisteredNodeCustomShader(
      _xHandle,
      bindUniformsCallback: (node) {
        flatShader.setUniform('u_color', _getHandleColor(_rightHandleColor, _xHandle));
        flatShader.setUniform('u_modelMat', node.getMatrix());
      },
    );
    Renderer.renderUnregisteredNodeCustomShader(
      _yHandle,
      bindUniformsCallback: (node) {
        flatShader.setUniform('u_color', _getHandleColor(_upHandleColor, _yHandle));
        flatShader.setUniform('u_modelMat', node.getMatrix());
      },
    );
  }
}
