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

  static Vector2Int? _boxSelectStart;
  static Vector2Int? _boxSelectCurrent;

  static Node? _draggedHandle;
  static Vector2Int? _dragStart;

  static void _clearDragState() {
    _boxSelectStart = null;
    _boxSelectCurrent = null;
    _draggedHandle = null;
    _dragStart = null;
  }

  // static Vector3 _getHandlePlanePoint(FlyCamera camera, Node node, Vector2Int mousePosition) {
  //   final (linePoint, viewMat, projMat) = camera.getState();
  //   final lineDirection = _getCameraRayDirection((mousePosition.$1, mousePosition.$2), (canvas.width, canvas.height), projMat, viewMat);

  //   final planePoint = _latestSelected!.wPos;
  //   final planeNormal = _handles.getHandleDirection(_latestSelected!, _draggedHandle!);

  //   final intersection = _linePlaneIntersection(linePoint, lineDirection, planePoint, planeNormal);
  // }

  static Future<void> init(FlyCamera camera) async {
    _outliner = await Outliner.create();
    _outliner.canvasSizeChanged(canvas.width, canvas.height);

    _clicker = await Clicker.create();
    _clicker.canvasSizeChanged(canvas.width, canvas.height);

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
        _draggedHandle = _clicker.clickUnregisteredNodes(x, y, [handleNodes.$1, handleNodes.$2, handleNodes.$3]);
        _dragStart = (x, y);
      } else {
        _draggedHandle = null;
        _dragStart = null;
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

        final delta = (x - _dragStart!.$1, y - _dragStart!.$2);

        final state = camera.getState();
        if (state != null) {
          final (linePoint, viewMat, projMat) = state;
          final lineDirection = _getCameraRayDirection((x, y), (canvas.width, canvas.height), projMat, viewMat);

          final planePoint = _latestSelected!.wPos;
          final planeNormal = _handles.getHandleDirection(_latestSelected!, _draggedHandle!);

          final intersection = _linePlaneIntersection(linePoint, lineDirection, planePoint, planeNormal);
          if (intersection != null) {
            _latestSelected!.wPos = intersection;
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
        // TODO: move node
        _draggedHandle = null;
      } else if (_boxSelectStart != null) {
        final dragDistance = Vector2(x.toDouble(), y.toDouble()).distanceTo(Vector2(_boxSelectStart!.$1.toDouble(), _boxSelectStart!.$2.toDouble()));
        if (dragDistance < _minDragDistance) {
          // click

          final node = _clicker.click(x, canvas.height - y);

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

          final nodes = _clicker.overlap(startX, startY, width, height);

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

  static void canvasSizeChanged(int width, int height) {
    _outliner.canvasSizeChanged(width, height);
    _clicker.canvasSizeChanged(width, height);
    _handles.canvasSizeChanged(width, height);
  }

  static void draw() {
    for (final (color, nodes) in _remoteSelected.values) {
      _outliner.draw(nodes, color);
    }
    _outliner.draw(_selected, _color);
    if (_latestSelected != null) _handles.drawHandles(_latestSelected!.wPos, _latestSelected!.wRot, _draggedHandle);
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

  static void selectOnly(Node? node) {
    _selected.clear();
    if (node != null) _selected.add(node);
    _latestSelected = node;
    _onSelectionChangedController.add(_selected);
  }

  static void selectOnlyMultiple(Set<Node> nodes) {
    _selected.clear();
    _selected.addAll(nodes);
    if (_selected.isEmpty) {
      _latestSelected = null;
    } else {
      // arbitrary
      _latestSelected = _selected.last;
    }
    _onSelectionChangedController.add(_selected);
  }

  static void toggleNode(Node node) {
    _toggleNode(node);
    _onSelectionChangedController.add(_selected);
  }

  static void toggleNodes(Set<Node> nodes) {
    if (nodes.isEmpty) return;
    for (final node in nodes) {
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
    _selected.add(node);
    _latestSelected = node;
    _onSelectionChangedController.add(_selected);
  }

  static void removeNode(Node node) {
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
