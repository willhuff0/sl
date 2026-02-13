import 'package:vector_math/vector_math.dart';

class Node {
  String name;
  Node? parent;
  final Set<Node> children = {};

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
    if (parent == null) return _lPos;
    if (_wDirty) {
      _updateWorldFromParent();
      _wDirty = false;
    }
    return _wPos;
  }

  Quaternion get wRot {
    if (parent == null) return _lRot;
    if (_wDirty) {
      _updateWorldFromParent();
      _wDirty = false;
    }
    return _wRot;
  }

  Vector3 get wScale {
    if (parent == null) return _lScale;
    if (_wDirty) {
      _updateWorldFromParent();
      _wDirty = false;
    }
    return _wScale;
  }

  void _updateWorldFromParent() {
    final scaledLPos = Vector3.copy(_lPos)..multiply(parent!.wScale);
    final rotatedLPos = parent!.wRot.rotate(scaledLPos);

    _wPos = parent!.wPos + rotatedLPos;
    _wRot = parent!.wRot * _lRot;

    _wScale = Vector3.copy(parent!.wScale);
    _wScale.multiply(_lScale);
  }

  void _markWDirty() {
    _wDirty = true;
    for (final child in children) {
      child._markWDirty();
    }
  }

  Matrix4 getMatrix() {
    return Matrix4.compose(wPos, wRot, wScale);
  }

  void addChild(Node child) {
    children.add(child);
    child.parent = this;
  }

  void removeChild(Node child) {
    children.remove(child);
    child.parent = null;
  }
}
