import 'dart:js_interop';
import 'dart:typed_data';

import 'package:sl_engine/components/mesh_component.dart';
import 'package:sl_engine/gl/buffer.dart';
import 'package:sl_engine/gl/debug_draw.dart';
import 'package:sl_engine/gl/gl.dart';
import 'package:sl_engine/gl/mesh.dart';
import 'package:sl_engine/gl/shader.dart';
import 'package:sl_engine/gl/texture.dart';
import 'package:sl_engine/node.dart';
import 'package:sl_engine/utils/bounds.dart';
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

enum AlphaMode {
  opaque,
  mask,
  blend,
}

class Material {
  Shader shader;
  final Map<String, dynamic> uniforms;
  final Map<int, Texture> textures;
  final bool doubleSided;
  final AlphaMode alphaMode;
  final double alphaCutoff;

  Material({
    required this.shader,
    required this.uniforms,
    required this.textures,
    this.doubleSided = false,
    this.alphaMode = AlphaMode.opaque,
    this.alphaCutoff = 0.5,
  });

  void bind() {
    shader.bind();
    uniforms.forEach((name, value) {
      shader.setUniform(name, value);
    });
    textures.forEach((slot, texture) {
      texture.bind(slot);
    });

    if (doubleSided) {
      gl.disable(GL.CULL_FACE);
    } else {
      gl.enable(GL.CULL_FACE);
      gl.cullFace(GL.BACK);
    }

    if (alphaMode == AlphaMode.blend) {
      gl.enable(GL.BLEND);
      gl.depthMask(false);
    } else {
      gl.disable(GL.BLEND);
      gl.depthMask(true);
    }
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

  static void clear() {
    _materials.clear();
    _nodes.clear();
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

    gl.bindVertexArray(null);
  }

  static void renderNodeCustomShader(Node node, {required void Function(Node node) bindUniformsCallback}) {
    _renderNodeCustomShader(node, bindUniformsCallback: bindUniformsCallback);
    gl.bindVertexArray(null);
  }

  static void _renderNodeCustomShader(Node node, {required void Function(Node node) bindUniformsCallback}) {
    for (final child in node.children) {
      _renderNodeCustomShader(child, bindUniformsCallback: bindUniformsCallback);
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
    gl.bindVertexArray(null);
  }

  static void renderUnregisteredNode(Node node) {
    _renderUnregisteredNode(node, transparentPass: false);
    _renderUnregisteredNode(node, transparentPass: true);
    gl.bindVertexArray(null);
    gl.enable(GL.BLEND);
    gl.depthMask(true);
    gl.disable(GL.CULL_FACE);
  }

  static void _renderUnregisteredNode(Node node, {required bool transparentPass}) {
    for (final child in node.children) {
      _renderUnregisteredNode(child, transparentPass: transparentPass);
    }

    final meshComponents = node.components.whereType<MeshComponent>();
    for (final meshComponent in meshComponents) {
      final isBlend = meshComponent.material.alphaMode == AlphaMode.blend;
      if (isBlend != transparentPass) continue;

      meshComponent.material.bind();
      meshComponent.mesh.bind();
      _setUboForNode(node);
      meshComponent.mesh.draw();
    }
  }

  static void renderAll() {
    // Render opaque and alpha-clipped materials
    _materials.forEach((material, meshes) {
      if (material.alphaMode == AlphaMode.blend) return;
      material.bind();
      meshes.forEach((mesh, nodes) {
        mesh.bind();
        for (final node in nodes) {
          _setUboForNode(node);
          mesh.draw();
        }
      });
    });

    // Render blended materials
    _materials.forEach((material, meshes) {
      if (material.alphaMode != AlphaMode.blend) return;
      material.bind();
      meshes.forEach((mesh, nodes) {
        mesh.bind();
        for (final node in nodes) {
          _setUboForNode(node);
          mesh.draw();
        }
      });
    });

    gl.bindVertexArray(null);
    gl.enable(GL.BLEND);
    gl.depthMask(true);
    gl.disable(GL.CULL_FACE);
  }

  static void drawAllBounds(Matrix4 viewMat) {
    _materials.forEach((material, meshes) {
      meshes.forEach((mesh, nodes) {
        for (final node in nodes) {
          final bounds = Bounds.computeLocalBounds(node);
          DebugDraw.drawBox3D(
            center: Vector3.zero(),
            size: bounds.max - bounds.min,
            rotation: node.wRot,
            color: Vector4(1.0, 0.0, 0.0, 0.2),
          );
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
