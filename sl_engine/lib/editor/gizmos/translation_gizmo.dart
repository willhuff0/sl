import 'package:sl_engine/editor/gizmos/gizmo.dart';
import 'package:sl_engine/editor/handles.dart';
import 'package:sl_engine/node.dart';
import 'package:sl_engine/gl/shader.dart';
import 'package:sl_engine/gl/gl.dart';
import 'package:sl_engine/editor/fly_camera.dart';
import 'package:sl_engine/utils/clicker.dart';
import 'package:sl_engine/utils/renderer.dart';
import 'package:vector_math/vector_math.dart';

class TranslationGizmo extends Gizmo {
  late final Node _forwardHandle;
  late final Node _rightHandle;
  late final Node _upHandle;
  late final Node _xyPlane;
  late final Node _yzPlane;
  late final Node _xzPlane;

  final Vector4 _forwardHandleColor = Vector4(0.0, 0.0, 1.0, 1.0);
  final Vector4 _rightHandleColor = Vector4(1.0, 0.0, 0.0, 1.0);
  final Vector4 _upHandleColor = Vector4(0.0, 1.0, 0.0, 1.0);
  final double _notDraggedHandleBrightness = 0.6;
  final double _notDraggedHandleOpacity = 0.8;

  Node? _draggedHandle;
  Vector3? _dragOffset;

  final Map<Node, Node> _clickToVisual = {};

  @override
  void init(Node root) {
    _forwardHandle = root.children.firstWhere((child) => child.name == '0_Z_Pos');
    _clickToVisual[root.children.firstWhere((child) => child.name == '0_Z_Pos_ClickTarget')] = _forwardHandle;

    _rightHandle = root.children.firstWhere((child) => child.name == '1_X_Pos');
    _clickToVisual[root.children.firstWhere((child) => child.name == '1_X_Pos_ClickTarget')] = _rightHandle;

    _upHandle = root.children.firstWhere((child) => child.name == '2_Y_Pos');
    _clickToVisual[root.children.firstWhere((child) => child.name == '2_Y_Pos_ClickTarget')] = _upHandle;

    _xyPlane = root.children.firstWhere((child) => child.name == '3_XY_Pos');
    _clickToVisual[root.children.firstWhere((child) => child.name == '3_XY_Pos')] = _xyPlane;

    _yzPlane = root.children.firstWhere((child) => child.name == '4_YZ_Pos');
    _clickToVisual[root.children.firstWhere((child) => child.name == '4_YZ_Pos')] = _yzPlane;

    _xzPlane = root.children.firstWhere((child) => child.name == '5_XZ_Pos');
    _clickToVisual[root.children.firstWhere((child) => child.name == '5_XZ_Pos')] = _xzPlane;
  }

  @override
  List<Node> getHandles() {
    return _clickToVisual.keys.toList();
  }

  bool _isAxisHandle(Node handle) {
    return handle == _forwardHandle || handle == _rightHandle || handle == _upHandle;
  }

  bool _isPlaneHandle(Node handle) {
    return handle == _xyPlane || handle == _yzPlane || handle == _xzPlane;
  }

  Vector3 _getHandleDirection(Node node, Node handle) {
    if (handle == _forwardHandle || handle == _xyPlane) {
      return node.getForwardVector();
    } else if (handle == _rightHandle || handle == _yzPlane) {
      return node.getRightVector();
    } else if (handle == _upHandle || handle == _xzPlane) {
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

    final eyeRay = Matrix4.inverted(projMat) * clipRay as Vector4;
    eyeRay.z = -1.0;
    eyeRay.w = 0.0;

    final worldRay = Matrix4.inverted(viewMat) * eyeRay as Vector4;

    return Vector3(worldRay.x, worldRay.y, worldRay.z)..normalize();
  }

  @override
  Node? onMouseDown(int x, int y, Node selectedNode, FlyCamera camera, Clicker clicker) {
    final clicked = clicker.clickUnregisteredNodes(x, y, getHandles(), screenScale: Handles.handleScreenProportion);
    _draggedHandle = clicked != null ? _clickToVisual[clicked] : null;

    if (_draggedHandle != null) {
      final state = camera.getState();
      if (state != null) {
        final (linePoint, viewMat, projMat) = state;
        final lineDirection = _getCameraRayDirection((x, y), (canvas.width, canvas.height), projMat, viewMat);

        final axisOrNormal = _getHandleDirection(selectedNode, _draggedHandle!);
        final planePoint = selectedNode.wPos;

        if (_isAxisHandle(_draggedHandle!)) {
          final cameraToObj = planePoint - linePoint;
          var planeNormal = axisOrNormal.cross(cameraToObj.cross(axisOrNormal));
          if (planeNormal.length2 == 0) {
            planeNormal = lineDirection;
          } else {
            planeNormal.normalize();
          }
          final intersection = _linePlaneIntersection(linePoint, lineDirection, planePoint, planeNormal);
          if (intersection != null) {
            final projected = planePoint + axisOrNormal * (intersection - planePoint).dot(axisOrNormal);
            _dragOffset = selectedNode.wPos - projected;
          } else {
            _dragOffset = Vector3.zero();
          }
        } else if (_isPlaneHandle(_draggedHandle!)) {
          final intersection = _linePlaneIntersection(linePoint, lineDirection, planePoint, axisOrNormal);
          if (intersection != null) {
            _dragOffset = selectedNode.wPos - intersection;
          } else {
            _dragOffset = Vector3.zero();
          }
        }
      }
    } else {
      _dragOffset = null;
    }
    return _draggedHandle;
  }

  @override
  void onMouseMove(int x, int y, Node selectedNode, FlyCamera camera) {
    if (_draggedHandle != null) {
      final state = camera.getState();
      if (state != null) {
        final (linePoint, viewMat, projMat) = state;
        final lineDirection = _getCameraRayDirection((x, y), (canvas.width, canvas.height), projMat, viewMat);

        final axisOrNormal = _getHandleDirection(selectedNode, _draggedHandle!);
        final planePoint = selectedNode.wPos - (_dragOffset ?? Vector3.zero());

        if (_isAxisHandle(_draggedHandle!)) {
          final cameraToObj = planePoint - linePoint;
          var planeNormal = axisOrNormal.cross(cameraToObj.cross(axisOrNormal));
          if (planeNormal.length2 == 0) {
            planeNormal = lineDirection;
          } else {
            planeNormal.normalize();
          }
          final intersection = _linePlaneIntersection(linePoint, lineDirection, planePoint, planeNormal);
          if (intersection != null) {
            final projected = planePoint + axisOrNormal * (intersection - planePoint).dot(axisOrNormal);
            selectedNode.wPos = projected + (_dragOffset ?? Vector3.zero());
          }
        } else if (_isPlaneHandle(_draggedHandle!)) {
          final intersection = _linePlaneIntersection(linePoint, lineDirection, planePoint, axisOrNormal);
          if (intersection != null) {
            selectedNode.wPos = intersection + (_dragOffset ?? Vector3.zero());
          }
        }
      }
    }
  }

  @override
  void onMouseUp() {
    _draggedHandle = null;
    _dragOffset = null;
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
      _forwardHandle,
      bindUniformsCallback: (node) {
        flatShader.setUniform('u_color', _getHandleColor(_forwardHandleColor, _forwardHandle));
        flatShader.setUniform('u_modelMat', node.getMatrix());
      },
    );
    Renderer.renderUnregisteredNodeCustomShader(
      _rightHandle,
      bindUniformsCallback: (node) {
        flatShader.setUniform('u_color', _getHandleColor(_rightHandleColor, _rightHandle));
        flatShader.setUniform('u_modelMat', node.getMatrix());
      },
    );
    Renderer.renderUnregisteredNodeCustomShader(
      _upHandle,
      bindUniformsCallback: (node) {
        flatShader.setUniform('u_color', _getHandleColor(_upHandleColor, _upHandle));
        flatShader.setUniform('u_modelMat', node.getMatrix());
      },
    );
    Renderer.renderUnregisteredNodeCustomShader(
      _xyPlane,
      bindUniformsCallback: (node) {
        flatShader.setUniform('u_color', _getHandleColor(_forwardHandleColor, _xyPlane));
        flatShader.setUniform('u_modelMat', node.getMatrix());
      },
    );
    Renderer.renderUnregisteredNodeCustomShader(
      _yzPlane,
      bindUniformsCallback: (node) {
        flatShader.setUniform('u_color', _getHandleColor(_rightHandleColor, _yzPlane));
        flatShader.setUniform('u_modelMat', node.getMatrix());
      },
    );
    Renderer.renderUnregisteredNodeCustomShader(
      _xzPlane,
      bindUniformsCallback: (node) {
        flatShader.setUniform('u_color', _getHandleColor(_upHandleColor, _xzPlane));
        flatShader.setUniform('u_modelMat', node.getMatrix());
      },
    );
  }
}
