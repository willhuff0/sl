import 'dart:async';
import 'dart:collection';

import 'package:sl_engine/gl/gl.dart';
import 'package:sl_engine/node.dart';
import 'package:sl_engine/editor_utils/outliner.dart';
import 'package:vector_math/vector_math.dart';

class Selector {
  static late final Outliner _outliner;
  static final Set<Node> _selected = {};
  static var _color = Vector4(1.0, 0.7, 0.0, 1.0);

  static final _onSelectionChangedController = StreamController<Set<Node>>.broadcast();
  static final onSelectionChanged = _onSelectionChangedController.stream;

  static Future<void> init() async {
    _outliner = await Outliner.create();
    _outliner.canvasSizeChanged(canvas.width, canvas.height);
  }

  static void canvasSizeChanged(int width, int height) {
    _outliner.canvasSizeChanged(width, height);
  }

  static void drawSelectionOutline() {
    _outliner.render(_selected, _color);
  }

  static UnmodifiableSetView<Node> getSelected() {
    return UnmodifiableSetView(_selected);
  }

  static void setOutlineColor(Vector4 color) {
    _color = color;
  }

  static void selectOnly(Node? node) {
    _selected.clear();
    if (node != null) _selected.add(node);
    _onSelectionChangedController.add(_selected);
  }

  static void toggleNode(Node node) {
    if (_selected.contains(node)) {
      _selected.remove(node);
    } else {
      _selected.add(node);
    }
    _onSelectionChangedController.add(_selected);
  }

  static void addNode(Node node) {
    _selected.add(node);
    _onSelectionChangedController.add(_selected);
  }

  static void removeNode(Node node) {
    _selected.remove(node);
    _onSelectionChangedController.add(_selected);
  }

  static void clear() {
    _selected.clear();
    _onSelectionChangedController.add(_selected);
  }
}
