import 'dart:collection';

import 'package:meta/meta.dart';
import 'package:vector_math/vector_math.dart';

abstract class Component {
  late Node? _node;
  var _enabled = true;

  Node get node => _node!;
  bool get enabled => _enabled;

  @protected
  void enterScene() {}
  @protected
  void exitScene() {}

  @protected
  void onEnable() {}
  @protected
  void onDisable() {}

  @nonVirtual
  void setEnabled(bool enabled) {
    if (enabled == _enabled) return;
    _enabled = enabled;
    if (!node.isFullyEnabled()) return;
    if (_enabled) {
      onEnable();
    } else {
      onDisable();
    }
  }
}

class Node {
  var _enabled = true;
  String name;
  Node? _parent;
  final List<Node> _children = [];
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

  bool get enabled {
    return _enabled;
  }

  Node? get parent {
    return _parent;
  }

  UnmodifiableListView<Node> get children {
    return UnmodifiableListView(_children);
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

  set wPos(Vector3 value) {
    _wPos = value;
    if (_parent == null) {
      _lPos = value;
    } else {
      final rotatedLPos = value - _parent!.wPos;
      final scaledLPos = _parent!.wRot.rotate(rotatedLPos);
      _lPos = Vector3.copy(scaledLPos)..divide(_parent!.wScale);
    }
    _markWDirty();
    _wDirty = false;
  }

  set wRot(Quaternion value) {
    _wRot = value;
    if (_parent == null) {
      _lRot = value;
    } else {
      _lRot = _parent!.wRot.inverted() * value;
    }
    _markWDirty();
    _wDirty = false;
  }

  set wScale(Vector3 value) {
    _wScale = value;
    if (_parent == null) {
      _lScale = value;
    } else {
      _lScale = Vector3.copy(value)..divide(_parent!.wScale);
    }
    _markWDirty();
    _wDirty = false;
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

  Vector3 getForwardVector() {
    return wRot.rotate(Vector3(0.0, 0.0, 1.0));
  }

  Vector3 getRightVector() {
    return wRot.rotate(Vector3(1.0, 0.0, 0.0));
  }

  Vector3 getUpVector() {
    return wRot.rotate(Vector3(0.0, 1.0, 0.0));
  }

  bool isFullyEnabled() {
    return _enabled && (parent?.isFullyEnabled() ?? true);
  }

  void setEnabled(bool enabled) {
    if (enabled == _enabled) return;
    _enabled = enabled;
    if (isFullyEnabled()) {
      _onEnable();
    } else {
      _onDisable();
    }
  }

  void addChild(Node child) {
    child.parent?.removeChild(child);
    _children.add(child);
    child._parent = this;
  }

  void removeChild(Node child) {
    if (_children.remove(child)) child._parent = null;
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
    final callOnEnable = isFullyEnabled();
    _enterScene(callOnEnable);
  }

  void _enterScene(bool callOnEnable) {
    for (final child in _children) {
      child._enterScene(callOnEnable);
    }
    for (final component in components) {
      component.enterScene();
      if (callOnEnable && component.enabled) {
        component.onEnable();
      }
    }
  }

  void exitScene() {
    final callOnDisable = isFullyEnabled();
    _exitScene(callOnDisable);
  }

  void _exitScene(bool callOnDisable) {
    for (final child in _children) {
      child._exitScene(callOnDisable);
    }
    for (final component in components) {
      if (callOnDisable && component.enabled) {
        component.onDisable();
      }
      component.exitScene();
    }
  }

  void _onEnable() {
    for (final child in _children) {
      child._onEnable();
    }
    for (final component in components) {
      if (component.enabled) {
        component.onEnable();
      }
    }
  }

  void _onDisable() {
    for (final child in _children) {
      child._onDisable();
    }
    for (final component in components) {
      if (component.enabled) {
        component.onDisable();
      }
    }
  }
}
