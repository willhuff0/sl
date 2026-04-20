import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:sl_engine/editor/fly_camera.dart';
import 'package:sl_engine/editor/handles.dart';
import 'package:sl_engine/gl/debug_draw.dart';
import 'package:sl_engine/gl/gl.dart';
import 'package:sl_engine/gl/shader.dart';
import 'package:sl_engine/input.dart';
import 'package:sl_engine/node.dart';
import 'package:sl_engine/editor/outliner.dart';
import 'package:sl_engine/utils/clicker.dart';
import 'package:vector_math/vector_math.dart';
import 'package:web/web.dart' as web;

const _multiselectBoxOpacity = 0.2;
const _minDragDistance = 14.0;

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

class Selector {
  static late final Outliner _outliner;
  static late final Clicker _clicker;
  static late final Handles _handles;

  static Node? _latestSelected;
  static final Set<Node> _selected = {};
  static Map<int, (Vector4, Set<Node>)> _remoteSelected = {};
  static var _color = Vector4(1.0, 0.7, 0.0, 1.0);

  static final _onSelectionChangedController = StreamController<Set<Node>>.broadcast();
  static final onSelectionChanged = _onSelectionChangedController.stream;

  static final _onSelectionTransformedController = StreamController<Set<Node>>.broadcast();
  static final onSelectionTransformed = _onSelectionTransformedController.stream;

  static Vector2Int? _boxSelectStart;
  static Vector2Int? _boxSelectCurrent;

  static Node? _draggedHandle;
  static Vector2Int? _dragStart;
  static Vector3? _dragOffset;

  static void _clearDragState() {
    _boxSelectStart = null;
    _boxSelectCurrent = null;
    _draggedHandle = null;
    _dragStart = null;
    _dragOffset = null;
  }

  static Future<void> init(FlyCamera camera) async {
    _outliner = await Outliner.create();
    _clicker = await Clicker.create();
    _handles = await Handles.create();

    Input.onFocusChanged.listen((focused) {
      if (!focused) {
        _clearDragState();
      }
    });

    canvas.onMouseDown.listen((event) {
      if (event.button != 0) return;
      final rect = canvas.getBoundingClientRect();
      final x = event.clientX - rect.left.toInt();
      final y = event.clientY - rect.top.toInt();

      if (_latestSelected != null) {
        final handleNodes = _handles.getHandles(_latestSelected!.wPos, _latestSelected!.wRot);
        _draggedHandle = _clicker.clickUnregisteredNodes(x, y, handleNodes);

        if (_draggedHandle != null) {
          final state = camera.getState();
          if (state != null) {
            final (linePoint, viewMat, projMat) = state;
            final lineDirection = _getCameraRayDirection((x, y), (canvas.width, canvas.height), projMat, viewMat);

            final axisOrNormal = _handles.getHandleDirection(_latestSelected!, _draggedHandle!);
            final planePoint = _latestSelected!.wPos;

            if (_handles.isAxisHandle(_draggedHandle!)) {
              final cameraToObj = planePoint - linePoint;
              var planeNormal = axisOrNormal.cross(cameraToObj.cross(axisOrNormal));
              if (planeNormal.length2 == 0) {
                // Fallback if camera ray is exactly on axis
                planeNormal = lineDirection;
              } else {
                planeNormal.normalize();
              }
              final intersection = _linePlaneIntersection(linePoint, lineDirection, planePoint, planeNormal);
              if (intersection != null) {
                final projected = planePoint + axisOrNormal * (intersection - planePoint).dot(axisOrNormal);
                _dragOffset = _latestSelected!.wPos - projected;
              } else {
                _dragOffset = Vector3.zero();
              }
            } else if (_handles.isPlaneHandle(_draggedHandle!)) {
              final intersection = _linePlaneIntersection(linePoint, lineDirection, planePoint, axisOrNormal);
              if (intersection != null) {
                _dragOffset = _latestSelected!.wPos - intersection;
              } else {
                _dragOffset = Vector3.zero();
              }
            }
          }
          _dragStart = (x, y);
        } else {
          _dragStart = null;
          _dragOffset = null;
        }
      } else {
        _draggedHandle = null;
        _dragStart = null;
        _dragOffset = null;
      }

      if (_draggedHandle == null) {
        _boxSelectStart = (x, y);
      } else {
        _boxSelectStart = null;
      }
      _boxSelectCurrent = null;
    });

    canvas.onMouseMove.listen((event) {
      if (_boxSelectStart != null) {
        final rect = canvas.getBoundingClientRect();
        final x = event.clientX - rect.left.toInt();
        final y = event.clientY - rect.top.toInt();

        final dragDistance = Vector2(x.toDouble(), y.toDouble()).distanceTo(Vector2(_boxSelectStart!.$1.toDouble(), _boxSelectStart!.$2.toDouble()));
        if (dragDistance >= _minDragDistance) {
          _boxSelectCurrent = (x, y);
        } else {
          _boxSelectCurrent = null;
        }
      }

      if (_latestSelected != null && _draggedHandle != null && _dragStart != null) {
        final rect = canvas.getBoundingClientRect();
        final x = event.clientX - rect.left.toInt();
        final y = event.clientY - rect.top.toInt();

        final state = camera.getState();
        if (state != null) {
          final (linePoint, viewMat, projMat) = state;
          final lineDirection = _getCameraRayDirection((x, y), (canvas.width, canvas.height), projMat, viewMat);

          final axisOrNormal = _handles.getHandleDirection(_latestSelected!, _draggedHandle!);
          final planePoint = _latestSelected!.wPos - (_dragOffset ?? Vector3.zero());

          if (_handles.isAxisHandle(_draggedHandle!)) {
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
              _latestSelected!.wPos = projected + (_dragOffset ?? Vector3.zero());
            }
          } else if (_handles.isPlaneHandle(_draggedHandle!)) {
            final intersection = _linePlaneIntersection(linePoint, lineDirection, planePoint, axisOrNormal);
            if (intersection != null) {
              _latestSelected!.wPos = intersection + (_dragOffset ?? Vector3.zero());
            }
          }
        }
      }
    });

    canvas.onMouseUp.listen((event) {
      if (event.button != 0) return;

      final rect = canvas.getBoundingClientRect();
      final x = event.clientX - rect.left.toInt();
      final y = event.clientY - rect.top.toInt();

      if (_latestSelected != null && _draggedHandle != null) {
        _onSelectionTransformedController.add({
          _latestSelected!,
        });
        _draggedHandle = null;
      } else if (_boxSelectStart != null) {
        final dragDistance = Vector2(x.toDouble(), y.toDouble()).distanceTo(Vector2(_boxSelectStart!.$1.toDouble(), _boxSelectStart!.$2.toDouble()));
        if (dragDistance < _minDragDistance) {
          // click

          var node = _clicker.click(x, canvas.height - y);
          if (node?.realNode != null) {
            node = node?.realNode;
          }

          if (event.ctrlKey) {
            if (node != null) {
              toggleNode(node);
            }
          } else {
            if (node == null) {
              clear();
            } else {
              selectOnly(node);
            }
          }
        } else {
          // box select

          final startX = min(_boxSelectStart!.$1, x);
          final startY = min(canvas.height - _boxSelectStart!.$2, canvas.height - y);
          final width = (_boxSelectStart!.$1 - x).abs();
          final height = (_boxSelectStart!.$2 - y).abs();

          final nodes = <Node>{};
          final fakeNodes = _clicker.overlap(startX, startY, width, height);
          for (final fakeNode in fakeNodes) {
            nodes.add(fakeNode.realNode ?? fakeNode);
          }

          if (event.ctrlKey) {
            toggleNodes(nodes);
          } else {
            selectOnlyMultiple(nodes);
          }
        }
      }

      _clearDragState();
    });
  }

  static void draw() {
    for (final (color, nodes) in _remoteSelected.values) {
      _outliner.draw(nodes, color);
    }
    _outliner.draw(_selected, _color);
    if (_latestSelected != null) {
      _handles.drawHandles(_latestSelected!.wPos, _latestSelected!.wRot, _draggedHandle);
    }
    if (_boxSelectStart != null && _boxSelectCurrent != null) {
      final startX = min(_boxSelectStart!.$1, _boxSelectCurrent!.$1);
      final startY = min(_boxSelectStart!.$2, _boxSelectCurrent!.$2);
      final width = (_boxSelectStart!.$1 - _boxSelectCurrent!.$1).abs();
      final height = (_boxSelectStart!.$2 - _boxSelectCurrent!.$2).abs();

      DebugDraw.drawBox2D(
        start: (startX, startY),
        size: (width, height),
        color: Vector4(_color.r, _color.g, _color.b, _multiselectBoxOpacity * _color.a),
      );
    }
  }

  static UnmodifiableSetView<Node> getSelected() {
    return UnmodifiableSetView(_selected);
  }

  static void setColor(Vector4 color) {
    _color = color;
  }

  static bool _isSelectable(Node node) {
    if (node.parent == null) return false;
    for (final remoteSelections in _remoteSelected.values) {
      for (final remoteSelected in remoteSelections.$2) {
        if (node == remoteSelected) return false;
      }
    }
    return true;
  }

  static void selectOnly(Node? node) {
    _selected.clear();
    if (node != null && _isSelectable(node)) {
      _selected.add(node);
      _latestSelected = node;
    } else {
      _latestSelected = null;
    }
    _onSelectionChangedController.add(_selected);
  }

  static void selectOnlyMultiple(Set<Node> nodes) {
    _selected.clear();
    _selected.addAll(nodes.where(_isSelectable));
    if (_selected.isEmpty) {
      _latestSelected = null;
    } else {
      // arbitrary
      _latestSelected = _selected.last;
    }
    _onSelectionChangedController.add(_selected);
  }

  static void toggleNode(Node node) {
    if (!_isSelectable(node)) return;
    _toggleNode(node);
    _onSelectionChangedController.add(_selected);
  }

  static void toggleNodes(Set<Node> nodes) {
    final selectableNodes = nodes.where(_isSelectable).toSet();
    if (selectableNodes.isEmpty) return;
    for (final node in selectableNodes) {
      _toggleNode(node);
    }
    _onSelectionChangedController.add(_selected);
  }

  static void _toggleNode(Node node) {
    if (_selected.contains(node)) {
      _selected.remove(node);
      if (_latestSelected == node) {
        if (_selected.isEmpty) {
          _latestSelected = null;
        } else {
          // arbitrary
          _latestSelected = _selected.last;
        }
      }
    } else {
      _selected.add(node);
      _latestSelected = node;
    }
  }

  static void addNode(Node node) {
    if (!_isSelectable(node)) return;
    _selected.add(node);
    _latestSelected = node;
    _onSelectionChangedController.add(_selected);
  }

  static void removeNode(Node node) {
    if (!_isSelectable(node)) return;
    _selected.remove(node);
    if (_latestSelected == node) {
      if (_selected.isEmpty) {
        _latestSelected = null;
      } else {
        // arbitrary
        _latestSelected = _selected.last;
      }
    }
    _onSelectionChangedController.add(_selected);
  }

  static void clear() {
    _selected.clear();
    _latestSelected = null;
    _onSelectionChangedController.add(_selected);
  }

  static void setRemoteSelected(Map<int, (Vector4, Set<Node>)> remoteSelection) {
    _remoteSelected = remoteSelection;
  }
}
