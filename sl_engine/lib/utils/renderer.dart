import 'dart:js_interop';
import 'dart:typed_data';

import 'package:sl_engine/components/mesh_component.dart';
import 'package:sl_engine/gl/buffer.dart';
import 'package:sl_engine/gl/gl.dart';
import 'package:sl_engine/gl/mesh.dart';
import 'package:sl_engine/gl/shader.dart';
import 'package:sl_engine/gl/texture.dart';
import 'package:sl_engine/node.dart';
import 'package:vector_math/vector_math.dart';

class RendererUniforms {
  final Matrix4 modelMat;
  final Matrix3 normalMat;

  RendererUniforms({
    required this.modelMat,
    required this.normalMat,
  });

  JSAny toJS() {
    final builder = BytesBuilder();

    builder.add(modelMat.storage.buffer.asUint8List());

    final normalMatStorage = normalMat.storage;
    final paddedNormalMat = Float32List(12);

    // Column 0
    paddedNormalMat[0] = normalMatStorage[0];
    paddedNormalMat[1] = normalMatStorage[1];
    paddedNormalMat[2] = normalMatStorage[2];

    // Column 1
    paddedNormalMat[4] = normalMatStorage[3];
    paddedNormalMat[5] = normalMatStorage[4];
    paddedNormalMat[6] = normalMatStorage[5];

    // Column 2
    paddedNormalMat[8] = normalMatStorage[6];
    paddedNormalMat[9] = normalMatStorage[7];
    paddedNormalMat[10] = normalMatStorage[8];

    builder.add(paddedNormalMat.buffer.asUint8List());

    return builder.toBytes().toJS;
  }
}

class Material {
  Shader shader;
  final Map<String, dynamic> uniforms;
  final Map<int, Texture> textures;

  Material({
    required this.shader,
    required this.uniforms,
    required this.textures,
  });

  void bind() {
    shader.bind();
    uniforms.forEach((name, value) {
      shader.setUniform(name, value);
    });
    textures.forEach((slot, texture) {
      texture.bind(slot);
    });
  }
}

class Renderer {
  static final Map<Material, Map<Mesh, Set<Node>>> _materials = {};
  static final Map<Node, (Material, Mesh)> _nodes = {};

  static late final Buffer _uniformBuffer;

  static void init() {
    _uniformBuffer = Buffer(GL.UNIFORM_BUFFER);
    _uniformBuffer.bind();
    _uniformBuffer.bindToUniformBuffer(1);
  }

  static void addNode(Node node, Material material, Mesh mesh) {
    final meshes = _materials[material] ??= {};
    final nodes = meshes[mesh] ??= {};
    nodes.add(node);

    _nodes[node] = (material, mesh);
  }

  static void removeNode(Node node, Material material, Mesh mesh) {
    final meshes = _materials[material]!;
    final nodes = meshes[mesh]!;
    nodes.remove(node);

    if (nodes.isEmpty) {
      meshes.remove(mesh);
    }
    if (meshes.isEmpty) {
      _materials.remove(material);
    }

    _nodes.remove(node);
  }

  static void renderUnregisteredNodeCustomShader(Node node, {required void Function(Node node) bindUniformsCallback}) {
    for (final child in node.children) {
      renderUnregisteredNodeCustomShader(child, bindUniformsCallback: bindUniformsCallback);
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
    final (_, mesh) = _nodes[node] ?? (null, null);
    if (mesh == null) return;

    mesh.bind();
    mesh.draw();
  }

  static void renderAllCustomShader({
    required void Function(Node node) bindUniformsCallback,
  }) {
    _nodes.forEach((node, meshes) {
      if (!node.enabled) return;

      bindUniformsCallback(node);
      final (_, mesh) = _nodes[node] ?? (null, null);
      if (mesh == null) return;

      mesh.bind();
      mesh.draw();
    });
  }

  static void renderUnregisteredNode(Node node) {
    for (final child in node.children) {
      renderUnregisteredNode(child);
    }

    final meshComponents = node.components.whereType<MeshComponent>();
    for (final meshComponents in meshComponents) {
      meshComponents.material.bind();
      meshComponents.mesh.bind();
      _setUboForNode(node);
      meshComponents.mesh.draw();
    }
  }

  static void renderAll() {
    _materials.forEach((material, meshes) {
      material.bind();
      meshes.forEach((mesh, nodes) {
        mesh.bind();
        for (final node in nodes) {
          _setUboForNode(node);
          mesh.draw();
        }
      });
    });
  }

  static void _setUboForNode(Node node) {
    final modelMat = node.getMatrix();
    final normalMat = modelMat.getNormalMatrix();

    _uniformBuffer.bind();
    _uniformBuffer.write(
      RendererUniforms(
        modelMat: modelMat,
        normalMat: normalMat,
      ).toJS(),
      GL.DYNAMIC_DRAW,
    );
  }
}
