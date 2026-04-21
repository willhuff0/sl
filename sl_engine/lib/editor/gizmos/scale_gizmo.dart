import 'package:sl_engine/editor/gizmos/gizmo.dart';
import 'package:sl_engine/editor/handles.dart';
import 'package:sl_engine/node.dart';
import 'package:sl_engine/gl/shader.dart';
import 'package:sl_engine/gl/gl.dart';
import 'package:sl_engine/editor/fly_camera.dart';
import 'package:sl_engine/utils/clicker.dart';
import 'package:sl_engine/utils/renderer.dart';
import 'package:vector_math/vector_math.dart';

const _uniformScaleSensitivity = 0.0025;

class ScaleGizmo extends Gizmo {
  late final Node _zHandle;
  late final Node _xHandle;
  late final Node _yHandle;
  late final Node _xyzHandle;

  final Vector4 _forwardHandleColor = Vector4(0.0, 0.0, 1.0, 1.0);
  final Vector4 _rightHandleColor = Vector4(1.0, 0.0, 0.0, 1.0);
  final Vector4 _upHandleColor = Vector4(0.0, 1.0, 0.0, 1.0);
  final Vector4 _xyzHandleColor = Vector4(1.0, 1.0, 1.0, 1.0);
  final double _notDraggedHandleBrightness = 0.6;
  final double _notDraggedHandleOpacity = 0.8;

  Node? _draggedHandle;
  Vector3? _dragStartPos;
  Vector3? _initialScale;
  Vector2? _dragStartMouse;

  final Map<Node, Node> _clickToVisual = {};

  @override
  void init(Node root) {
    _zHandle = root.children.firstWhere((child) => child.name == '0_Z_Scale');
    _clickToVisual[root.children.firstWhere((child) => child.name == '0_Z_Scale_ClickTarget')] = _zHandle;

    _xHandle = root.children.firstWhere((child) => child.name == '1_X_Scale');
    _clickToVisual[root.children.firstWhere((child) => child.name == '1_X_Scale_ClickTarget')] = _xHandle;

    _yHandle = root.children.firstWhere((child) => child.name == '2_Y_Scale');
    _clickToVisual[root.children.firstWhere((child) => child.name == '2_Y_Scale_ClickTarget')] = _yHandle;

    _xyzHandle = root.children.firstWhere((child) => child.name == '3_XYZ_Scale');
    _clickToVisual[root.children.firstWhere((child) => child.name == '3_XYZ_Scale_ClickTarget')] = _xyzHandle;
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

  @override
  Node? onMouseDown(int x, int y, Node selectedNode, FlyCamera camera, Clicker clicker) {
    final clicked = clicker.clickUnregisteredNodes(x, y, getHandles(), screenScale: Handles.handleScreenProportion);
    _draggedHandle = clicked != null ? _clickToVisual[clicked] : null;

    if (_draggedHandle != null) {
      final state = camera.getState();
      if (state != null) {
        if (_draggedHandle == _xyzHandle) {
          _dragStartMouse = Vector2(x.toDouble(), y.toDouble());
          _initialScale = Vector3.copy(selectedNode.lScale);
        } else {
          final (linePoint, viewMat, projMat) = state;
          final lineDirection = _getCameraRayDirection((x, y), (canvas.width, canvas.height), projMat, viewMat);

          final axisDir = _getHandleAxis(selectedNode, _draggedHandle!);
          final planePoint = selectedNode.wPos;

          final cameraToObj = planePoint - linePoint;
          var planeNormal = axisDir.cross(cameraToObj.cross(axisDir));
          if (planeNormal.length2 == 0) {
            planeNormal = lineDirection;
          } else {
            planeNormal.normalize();
          }

          final intersection = _linePlaneIntersection(linePoint, lineDirection, planePoint, planeNormal);
          if (intersection != null) {
            final projected = planePoint + axisDir * (intersection - planePoint).dot(axisDir);
            _dragStartPos = projected;
            _initialScale = Vector3.copy(selectedNode.lScale);
          } else {
            _dragStartPos = selectedNode.wPos;
            _initialScale = Vector3.copy(selectedNode.lScale);
          }
        }
      }
    } else {
      _dragStartPos = null;
      _initialScale = null;
      _dragStartMouse = null;
    }
    return _draggedHandle;
  }

  @override
  void onMouseMove(int x, int y, Node selectedNode, FlyCamera camera) {
    if (_draggedHandle != null && _initialScale != null) {
      if (_draggedHandle == _xyzHandle && _dragStartMouse != null) {
        final mouseCurrent = Vector2(x.toDouble(), y.toDouble());
        final mouseDelta = mouseCurrent - _dragStartMouse!;
        final delta = mouseDelta.x - mouseDelta.y;
        final scaleFactor = 1.0 + (delta * _uniformScaleSensitivity);
        selectedNode.lScale = _initialScale! * scaleFactor;
      } else if (_dragStartPos != null) {
        final state = camera.getState();
        if (state != null) {
          final (linePoint, viewMat, projMat) = state;
          final lineDirection = _getCameraRayDirection((x, y), (canvas.width, canvas.height), projMat, viewMat);

          final axisDir = _getHandleAxis(selectedNode, _draggedHandle!);
          final planePoint = selectedNode.wPos;

          final cameraToObj = planePoint - linePoint;
          var planeNormal = axisDir.cross(cameraToObj.cross(axisDir));
          if (planeNormal.length2 == 0) {
            planeNormal = lineDirection;
          } else {
            planeNormal.normalize();
          }

          final intersection = _linePlaneIntersection(linePoint, lineDirection, planePoint, planeNormal);
          if (intersection != null) {
            final projected = planePoint + axisDir * (intersection - planePoint).dot(axisDir);

            final totalVec = projected - planePoint;
            final startVec = _dragStartPos! - planePoint;

            final totalDist = totalVec.dot(axisDir);
            final startDist = startVec.dot(axisDir);

            if (startDist.abs() > 0.001) {
              final scaleFactor = totalDist / startDist;
              final newScale = Vector3.copy(_initialScale!);
              if (_draggedHandle == _xHandle) {
                newScale.x *= scaleFactor;
              } else if (_draggedHandle == _yHandle) {
                newScale.y *= scaleFactor;
              } else if (_draggedHandle == _zHandle) {
                newScale.z *= scaleFactor;
              }
              selectedNode.lScale = newScale;
            }
          }
        }
      }
    }
  }

  @override
  void onMouseUp() {
    _draggedHandle = null;
    _dragStartPos = null;
    _initialScale = null;
    _dragStartMouse = null;
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
    Renderer.renderUnregisteredNodeCustomShader(
      _xyzHandle,
      bindUniformsCallback: (node) {
        flatShader.setUniform('u_color', _getHandleColor(_xyzHandleColor, _xyzHandle));
        flatShader.setUniform('u_modelMat', node.getMatrix());
      },
    );
  }
}
