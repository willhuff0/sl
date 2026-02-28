import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:sl_engine/editor_utils/handles.dart';
import 'package:sl_engine/gl/debug_draw.dart';
import 'package:sl_engine/gl/gl.dart';
import 'package:sl_engine/gl/shader.dart';
import 'package:sl_engine/input.dart';
import 'package:sl_engine/node.dart';
import 'package:sl_engine/editor_utils/outliner.dart';
import 'package:sl_engine/utils/clicker.dart';
import 'package:vector_math/vector_math.dart';
import 'package:web/web.dart' as web;

const _multiselectBoxOpacity = 0.2;
const _minDragDistance = 14.0;

class Selector {
  static late final Outliner _outliner;
  static late final Clicker _clicker;
  static late final Handles _handles;

  static Node? _latestSelected;
  static final Set<Node> _selected = {};
  static var _color = Vector4(1.0, 0.7, 0.0, 1.0);

  static final _onSelectionChangedController = StreamController<Set<Node>>.broadcast();
  static final onSelectionChanged = _onSelectionChangedController.stream;

  static Vector2Int? _dragStart;
  static Vector2Int? _dragCurrent;
  static Node? _draggedHandle;

  static Future<void> init() async {
    _outliner = await Outliner.create();
    _outliner.canvasSizeChanged(canvas.width, canvas.height);

    _clicker = await Clicker.create();
    _clicker.canvasSizeChanged(canvas.width, canvas.height);

    _handles = await Handles.create();

    Input.onFocusChanged.listen((focused) {
      if (!focused) {}
    });

    canvas.onMouseDown.listen((event) {
      if (event.button != 0) return;
      final rect = canvas.getBoundingClientRect();
      final x = event.clientX - rect.left.toInt();
      final y = event.clientY - rect.top.toInt();

      _dragStart = (x, y);
      _dragCurrent = null;

      if (_latestSelected != null) {
        final handleNodes = _handles.getHandles(_latestSelected!.wPos, _latestSelected!.wRot);
        _draggedHandle = _clicker.clickUnregisteredNodes(x, y, [handleNodes.$1, handleNodes.$2, handleNodes.$3]);
      } else {
        _draggedHandle = null;
      }
    });

    canvas.onMouseMove.listen((event) {
      if (_dragStart != null) {
        final rect = canvas.getBoundingClientRect();
        final x = event.clientX - rect.left.toInt();
        final y = event.clientY - rect.top.toInt();

        final dragDistance = Vector2(x.toDouble(), y.toDouble()).distanceTo(Vector2(_dragStart!.$1.toDouble(), _dragStart!.$2.toDouble()));
        if (dragDistance >= _minDragDistance) {
          _dragCurrent = (x, y);
        } else {
          _dragCurrent = null;
        }
      }

      if (_latestSelected != null && _draggedHandle != null) {
        // TODO: move node
      }
    });

    canvas.onMouseUp.listen((event) {
      if (event.button != 0) return;
      if (_dragStart == null) return;

      final rect = canvas.getBoundingClientRect();
      final x = event.clientX - rect.left.toInt();
      final y = event.clientY - rect.top.toInt();

      if (_latestSelected != null && _draggedHandle != null) {
        // TODO: move node
      } else {
        final dragDistance = Vector2(x.toDouble(), y.toDouble()).distanceTo(Vector2(_dragStart!.$1.toDouble(), _dragStart!.$2.toDouble()));
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

          final startX = min(_dragStart!.$1, x);
          final startY = min(canvas.height - _dragStart!.$2, canvas.height - y);
          final width = (_dragStart!.$1 - x).abs();
          final height = (_dragStart!.$2 - y).abs();

          final nodes = _clicker.overlap(startX, startY, width, height);

          if (event.ctrlKey) {
            toggleNodes(nodes);
          } else {
            selectOnlyMultiple(nodes);
          }
        }
      }

      _dragStart = null;
      _dragCurrent = null;
      _draggedHandle = null;
    });
  }

  static void canvasSizeChanged(int width, int height) {
    _outliner.canvasSizeChanged(width, height);
    _clicker.canvasSizeChanged(width, height);
    _handles.canvasSizeChanged(width, height);
  }

  static void draw() {
    _outliner.draw(_selected, _color);
    if (_latestSelected != null) _handles.drawHandles(_latestSelected!.wPos, _latestSelected!.wRot);
    if (_dragStart != null && _dragCurrent != null) {
      final startX = min(_dragStart!.$1, _dragCurrent!.$1);
      final startY = min(_dragStart!.$2, _dragCurrent!.$2);
      final width = (_dragStart!.$1 - _dragCurrent!.$1).abs();
      final height = (_dragStart!.$2 - _dragCurrent!.$2).abs();

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
}
