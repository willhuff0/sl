import 'dart:collection';

import 'package:sl_engine/gl/mesh.dart';
import 'package:sl_engine/node.dart';

class Renderer {
  static final Map<Node, List<Mesh>> _nodes = {};

  static void addMeshToNode(Node node, Mesh mesh) {
    var meshes = _nodes[node];
    meshes ??= _nodes[node] = [];
    meshes.add(mesh);
  }

  static UnmodifiableListView<Mesh> getNodeMeshes(Node node) {
    return UnmodifiableListView(_nodes[node] ?? []);
  }

  static void renderWithCustomShader({
    required void Function(Node node) bindUniformsCallback,
  }) {
    _nodes.forEach((node, meshes) {
      bindUniformsCallback(node);
      for (final mesh in meshes) {
        mesh.bind();
        mesh.draw();
      }
    });
  }
}
