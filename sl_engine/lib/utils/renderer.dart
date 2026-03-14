import 'dart:collection';

import 'package:sl_engine/components/mesh_component.dart';
import 'package:sl_engine/gl/mesh.dart';
import 'package:sl_engine/gl/shader.dart';
import 'package:sl_engine/node.dart';

class Material {
  Shader shader;
  final Map<String, dynamic> uniforms = {};

  Material({required this.shader});
}

class Renderer {
  static final Map<Material, Set<Mesh>> _materials = {};
  static final Map<Node, Mesh> _nodes = {};

  static UnmodifiableListView<Mesh> getNodeMeshes(Node node) {
    return UnmodifiableListView(_nodes[node] ?? []);
  }

  static void addMesh(Node node, Material material, Mesh mesh) {
    var meshes = _nodes[node];
    meshes ??= _nodes[node] = [];
    meshes.add(mesh);
  }

  static void removeMesh(Node node, Material material, Mesh mesh) {
    var meshes = _nodes[node];
    meshes?.remove(mesh);
    if (meshes?.isEmpty ?? true) {
      _nodes.remove(node);
    }
  }

  static void renderDisabledNodeCustomShader(Node node, {required void Function(Node node) bindUniformsCallback}) {
    for (final child in node.children) {
      renderDisabledNodeCustomShader(child, bindUniformsCallback: bindUniformsCallback);
    }

    final meshes = node.components.whereType<MeshComponent>().map((component) => component.mesh);
    if (meshes.isEmpty) return;

    bindUniformsCallback(node);
    for (final mesh in meshes) {
      mesh.bind();
      mesh.draw();
    }
  }

  static void renderNodeCustomShader(Node node, {required void Function(Node node) bindUniformsCallback}) {
    for (final child in node.children) {
      renderNodeCustomShader(child, bindUniformsCallback: bindUniformsCallback);
    }

    bindUniformsCallback(node);
    final meshes = _nodes[node] ?? [];
    for (final mesh in meshes) {
      mesh.bind();
      mesh.draw();
    }
  }

  static void renderAllCustomShader({
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
