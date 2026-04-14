import 'package:sl_engine/components/mesh_component.dart';
import 'package:sl_engine/node.dart';
import 'package:vector_math/vector_math.dart';

class _ComputedBounds {
  var minX = double.infinity;
  var minY = double.infinity;
  var minZ = double.infinity;
  var maxX = double.negativeInfinity;
  var maxY = double.negativeInfinity;
  var maxZ = double.negativeInfinity;
}

class Bounds {
  static Aabb3 computeBounds(Node node) {
    final bounds = _ComputedBounds();
    _computeBounds(node, bounds);
    return Aabb3.minMax(
      Vector3(bounds.minX, bounds.minY, bounds.minZ),
      Vector3(bounds.maxX, bounds.maxY, bounds.maxZ),
    );
  }

  static final _meshBounds = Aabb3();
  static void _computeBounds(Node node, _ComputedBounds bounds) {
    for (final component in node.components) {
      if (component is! MeshComponent) continue;

      component.mesh.bounds.transformed(node.getMatrix(), _meshBounds);
      if (_meshBounds.min.x < bounds.minX) bounds.minX = _meshBounds.min.x;
      if (_meshBounds.max.x > bounds.maxX) bounds.maxX = _meshBounds.max.x;
      if (_meshBounds.min.y < bounds.minY) bounds.minY = _meshBounds.min.y;
      if (_meshBounds.max.y > bounds.maxY) bounds.maxY = _meshBounds.max.y;
      if (_meshBounds.min.z < bounds.minZ) bounds.minZ = _meshBounds.min.z;
      if (_meshBounds.max.z > bounds.maxZ) bounds.maxZ = _meshBounds.max.z;
    }
    for (final child in node.children) {
      _computeBounds(child, bounds);
    }
  }
}
