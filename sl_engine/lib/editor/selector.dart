import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:sl_engine/editor/fly_camera.dart';
import 'package:sl_engine/editor/handles.dart';
import 'package:sl_engine/gl/debug_draw.dart';
import 'package:sl_engine/gl/gl.dart';
import 'package:sl_engine/input.dart';
import 'package:sl_engine/node.dart';
import 'package:sl_engine/editor/outliner.dart';
import 'package:sl_engine/utils/clicker.dart';
import 'package:vector_math/vector_math.dart';
import 'package:web/web.dart' as web;

enum GizmoType {
  translation,
  rotation,
  scale,
}

const _multiselectBoxOpacity = 0.2;
const _minDragDistance = 14.0;

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

  static final _onGizmoChangedController = StreamController<GizmoType>.broadcast();
  static final onGizmoChanged = _onGizmoChangedController.stream;

  static Vector2Int? _boxSelectStart;
  static Vector2Int? _boxSelectCurrent;

  static Node? _draggedHandle;

  static void _clearDragState() {
    _boxSelectStart = null;
    _boxSelectCurrent = null;
    _draggedHandle = null;
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
        _draggedHandle = _handles.activeGizmo.onMouseDown(x, y, _latestSelected!, camera, _clicker);
      } else {
        _draggedHandle = null;
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

      if (_latestSelected != null && _draggedHandle != null) {
        final rect = canvas.getBoundingClientRect();
        final x = event.clientX - rect.left.toInt();
        final y = event.clientY - rect.top.toInt();

        _handles.activeGizmo.onMouseMove(x, y, _latestSelected!, camera);
      }
    });

    canvas.onMouseUp.listen((event) {
      if (event.button != 0) return;

      final rect = canvas.getBoundingClientRect();
      final x = event.clientX - rect.left.toInt();
      final y = event.clientY - rect.top.toInt();

      if (_latestSelected != null && _draggedHandle != null) {
        _handles.activeGizmo.onMouseUp();
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

  static void setGizmoType(GizmoType gizmoType) {
    try {
      _onGizmoChangedController.add(gizmoType);
      switch (gizmoType) {
        case .translation:
          _handles.activeGizmo = _handles.translationGizmo;
          break;
        case .rotation:
          _handles.activeGizmo = _handles.rotationGizmo;
          break;
        case .scale:
          _handles.activeGizmo = _handles.scaleGizmo;
          break;
      }
    } catch (_) {}
  }

  static void draw() {
    for (final (color, nodes) in _remoteSelected.values) {
      _outliner.draw(nodes, color);
    }
    _outliner.draw(_selected, _color);
    if (_latestSelected != null) {
      _handles.drawHandles(_latestSelected!.wPos, _latestSelected!.wRot);
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
