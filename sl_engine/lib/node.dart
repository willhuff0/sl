import 'dart:collection';

import 'package:vector_math/vector_math.dart';

abstract class Component {
  late Node? _node;

  Node get node => _node!;

  void enterScene();
  void exitScene();
}

class Node {
  String name;
  Node? _parent;
  final Set<Node> _children = {};
  final List<Component> _components = [];

  Vector3 _lPos = Vector3.zero();
  Quaternion _lRot = Quaternion.identity();
  Vector3 _lScale = Vector3(1.0, 1.0, 1.0);

  bool _wDirty = true;
  Vector3 _wPos = Vector3(double.nan, double.nan, double.nan);
  Quaternion _wRot = Quaternion(double.nan, double.nan, double.nan, double.nan);
  Vector3 _wScale = Vector3(double.nan, double.nan, double.nan);

  Node({required this.name, Vector3? pos, Quaternion? rot, Vector3? scale}) {
    if (pos != null) _lPos = pos;
    if (rot != null) _lRot = rot;
    if (scale != null) _lScale = scale;
  }

  Node? get parent {
    return _parent;
  }

  UnmodifiableSetView<Node> get children {
    return UnmodifiableSetView(_children);
  }

  UnmodifiableListView<Component> get components {
    return UnmodifiableListView(_components);
  }

  Vector3 get lPos {
    return _lPos;
  }

  Quaternion get lRot {
    return _lRot;
  }

  Vector3 get lScale {
    return _lScale;
  }

  set lPos(Vector3 value) {
    _lPos = value;
    _markWDirty();
  }

  set lRot(Quaternion value) {
    _lRot = value;
    _markWDirty();
  }

  set lScale(Vector3 value) {
    _lScale = value;
    _markWDirty();
  }

  Vector3 get wPos {
    if (_parent == null) return _lPos;
    if (_wDirty) {
      _updateWorldFromParent();
      _wDirty = false;
    }
    return _wPos;
  }

  Quaternion get wRot {
    if (_parent == null) return _lRot;
    if (_wDirty) {
      _updateWorldFromParent();
      _wDirty = false;
    }
    return _wRot;
  }

  Vector3 get wScale {
    if (_parent == null) return _lScale;
    if (_wDirty) {
      _updateWorldFromParent();
      _wDirty = false;
    }
    return _wScale;
  }

  void _updateWorldFromParent() {
    final scaledLPos = Vector3.copy(_lPos)..multiply(_parent!.wScale);
    final rotatedLPos = _parent!.wRot.inverted().rotate(scaledLPos);

    _wPos = _parent!.wPos + rotatedLPos;
    _wRot = _parent!.wRot * _lRot;

    _wScale = Vector3.copy(_parent!.wScale);
    _wScale.multiply(_lScale);
  }

  void _markWDirty() {
    _wDirty = true;
    for (final child in _children) {
      child._markWDirty();
    }
  }

  Matrix4 getMatrix() {
    return Matrix4.compose(wPos, wRot, wScale);
  }

  void addChild(Node child) {
    _children.add(child);
    child._parent = this;
  }

  void removeChild(Node child) {
    _children.remove(child);
    child._parent = null;
  }

  void addComponent(Component component) {
    _components.add(component);
    component._node = this;
  }

  void removeComponent(int index) {
    final component = _components.removeAt(index);
    component._node = null;
  }

  void enterScene() {
    for (final child in _children) {
      child.enterScene();
    }
    for (final component in components) {
      component.enterScene();
    }
  }

  void exitScene() {
    for (final child in _children) {
      child.exitScene();
    }
    for (final component in components) {
      component.exitScene();
    }
  }
}
