import 'dart:collection';

import 'package:sl_engine/components/mesh_component.dart';
import 'package:sl_engine/gl/mesh.dart';
import 'package:sl_engine/node.dart';

class Renderer {
  static final Map<Node, List<Mesh>> _nodes = {};

  static void addMeshToNode(Node node, Mesh mesh) {
    var meshes = _nodes[node];
    meshes ??= _nodes[node] = [];
    meshes.add(mesh);
  }

  static void removeMeshFromNode(Node node, Mesh mesh) {
    var meshes = _nodes[node];
    meshes?.remove(mesh);
    if (meshes?.isEmpty ?? true) {
      _nodes.remove(node);
    }
  }

  static void renderUnregisteredNode(Node node, {required void Function(Node node) bindUniformsCallback}) {
    for (final child in node.children) {
      renderUnregisteredNode(child, bindUniformsCallback: bindUniformsCallback);
    }

    final meshes = node.components.whereType<MeshComponent>().map((component) => component.mesh);
    if (meshes.isEmpty) return;

    bindUniformsCallback(node);
    for (final mesh in meshes) {
      mesh.bind();
      mesh.draw();
    }
  }

  static void renderNode(Node node, {required void Function(Node node) bindUniformsCallback}) {
    for (final child in node.children) {
      renderNode(child, bindUniformsCallback: bindUniformsCallback);
    }

    bindUniformsCallback(node);
    final meshes = _nodes[node] ?? [];
    for (final mesh in meshes) {
      mesh.bind();
      mesh.draw();
    }
  }

  static UnmodifiableListView<Mesh> getNodeMeshes(Node node) {
    return UnmodifiableListView(_nodes[node] ?? []);
  }

  static void renderAll({
    required void Function(Node node) bindUniformsCallback,
  }) {
    _nodes.forEach((node, meshes) {
      if (!node.enabled) return;
      bindUniformsCallback(node);
      for (final mesh in meshes) {
        mesh.bind();
        mesh.draw();
      }
    });
  }
}
