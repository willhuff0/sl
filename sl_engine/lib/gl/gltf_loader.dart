import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:sl_engine/components/mesh_component.dart';
import 'package:sl_engine/gl/buffer.dart';
import 'package:sl_engine/gl/gl.dart';
import 'package:sl_engine/gl/mesh.dart';
import 'package:path/path.dart' as p;
import 'package:sl_engine/logger.dart';
import 'package:sl_engine/node.dart';
import 'package:sl_engine/utils/resource_loader.dart';
import 'package:vector_math/vector_math.dart';
import 'package:web/web.dart' as web;
import 'package:http/http.dart' as http;

class _GLTFMeshPrimitive implements Mesh {
  final web.WebGLVertexArrayObject vao;
  final int topology;
  final int offset;
  final int count;
  final int? indexType;

  _GLTFMeshPrimitive._({
    required this.vao,
    required this.topology,
    required this.offset,
    required this.count,
    required this.indexType,
  });

  @override
  void bind() {
    gl.bindVertexArray(vao);
  }

  @override
  void draw() {
    if (indexType != null) {
      gl.drawElements(topology, count, indexType!, offset);
    } else {
      gl.drawArrays(topology, offset, count);
    }
  }

  @override
  void unbind() {
    gl.bindVertexArray(null);
  }
}

Vector3 _listToVector3(List<dynamic> list) {
  return Vector3(list[0], list[1], list[2]);
}

Quaternion _listToQuaternion(List<dynamic> list) {
  return Quaternion(list[0], list[1], list[2], list[3]);
}

const _componentSizes = {
  'SCALAR': 1,
  'VEC2': 2,
  'VEC3': 3,
  'VEC4': 4,
  'MAT2': 4,
  'MAT3': 9,
  'MAT4': 16,
};

const _attributeInfo = {
  'POSITION': (0, 3),
  'NORMAL': (1, 3),
  'TANGENT': (2, 3),
  'TEXCOORD_0': (3, 2),
};

class GLTF {
  final Node root;
  final String? copyright;
  final String? generator;

  GLTF({
    required this.root,
    required this.copyright,
    required this.generator,
  });

  static Future<GLTF?> load(String path, {String? sceneName}) async {
    final directory = p.dirname(path);
    final extension = p.extension(path);

    Uint8List? glbBuffer;

    Map<String, dynamic> json;
    switch (extension) {
      case '.glb':
        final response = await ResourceLoader.loadBytes(path);
        if (response == null) return null;
        final buffer = response.buffer;
        final bytes = buffer.asByteData();

        final magic = bytes.getUint32(0, Endian.little);
        if (magic != 0x46546C67) {
          Logger.log('Tried to load a GLTF \'$path\' which is malformed (incorrect magic number).', .warning);
          return null;
        }

        final version = bytes.getUint32(4, Endian.little);
        if (version != 2) {
          Logger.log('Tried to load a GLTF \'$path\' with unsupported version \'$version\'. Use version \'2.0\'.', .warning);
          return null;
        }

        final length = bytes.getUint32(8, Endian.little);

        final jsonChunkLength = bytes.getUint32(12, Endian.little);
        final jsonChunkType = bytes.getUint32(16, Endian.little);
        if (jsonChunkType != 0x4E4F534A) {
          Logger.log('Tried to load a GLTF \'$path\' which is malformed (first chunk is not json).', .warning);
          return null;
        }
        final jsonChunkData = buffer.asUint8List(20, jsonChunkLength);
        final jsonChunkText = utf8.decode(jsonChunkData);
        json = jsonDecode(jsonChunkText);

        glbBuffer = buffer.asUint8List(jsonChunkLength, length - jsonChunkLength - 20);
        break;
      case '.gltf':
        final response = await ResourceLoader.loadString(path);
        if (response == null) return null;
        json = jsonDecode(response);
        break;
      default:
        Logger.log('A file path with an unsupported extension \'$path\' was passed to the GLTF loader.', .warning);
        return null;
    }

    final asset = json['asset'] as Map<String, dynamic>;
    final gltfVersion = asset['version'];
    if (gltfVersion != '2.0') {
      Logger.log('Tried to load a GLTF \'$path\' with unsupported version \'$gltfVersion\'. Use version \'2.0\'.', .warning);
      return null;
    }
    final copyright = asset['copyright'];
    final generator = asset['generator'];

    Map<String, dynamic>? scene;
    if (sceneName != null) {
      final scenes = json['scenes'];
      for (final s in scenes) {
        if (s['name'] != sceneName) continue;
        scene = s;
        break;
      }
    }
    scene ??= json['scenes'][0];

    var rootName = scene!['name'] as String?;
    if (rootName == null || rootName.isEmpty) {
      rootName = p.basenameWithoutExtension(path);
    }

    final rootNodeIndices = scene['nodes'] as List<dynamic>;

    final nodes = json['nodes'] as List<dynamic>;
    final meshes = json['meshes'] as List<dynamic>;
    final accessors = json['accessors'] as List<dynamic>;
    final bufferViews = json['bufferViews'] as List<dynamic>;
    final buffers = json['buffers'] as List<dynamic>;

    final bufferIndexToBytes = <int, Uint8List>{};
    final bufferViewIndexToGpuBuffer = <int, Buffer>{};

    Future<Uint8List?> getBufferBytes(int index) async {
      var cache = bufferIndexToBytes[index];
      if (cache == null) {
        final buffer = buffers[index];
        final uriString = buffer['uri'];
        if (uriString == null) {
          if (glbBuffer == null) {
            Logger.log('Tried to load a GLTF \'$path\' which is malformed (references GLB-stored buffer which is not present).', .warning);
            return null;
          }
          cache = bufferIndexToBytes[index] = glbBuffer;
        } else {
          final uri = Uri.parse(uriString);
          if (uri.data != null) {
            cache = bufferIndexToBytes[index] = uri.data!.contentAsBytes();
          } else if (uri.isScheme('HTTP') || uri.isScheme('HTTPS')) {
            final response = await http.get(uri);
            if (response.statusCode != 200) {
              Logger.log('Failed to load a buffer over the network while loading a GLTF \'$path\'. HTTP GET to \'$uri\' returned status code ${response.statusCode}.', .warning);
              return null;
            }
            cache = bufferIndexToBytes[index] = response.bodyBytes;
          } else {
            final resolved = p.join(directory, uri.path);
            final bytes = await ResourceLoader.loadBytes(resolved);
            if (bytes == null) return null;
            cache = bufferIndexToBytes[index] = bytes;
          }
        }
      }
      return cache;
    }

    Future<Buffer?> getAndBindGpuBufferFromView(int index) async {
      var cache = bufferViewIndexToGpuBuffer[index];
      if (cache == null) {
        final bufferView = bufferViews[index];
        final byteOffset = bufferView['byteOffset'] ?? 0;
        final byteLength = bufferView['byteLength'];
        final bufferIndex = bufferView['buffer'] as int;
        final bytes = await getBufferBytes(bufferIndex);
        if (bytes == null) return null;
        final target = bufferView['target'] as int?;
        if (target == null) {
          Logger.log('Tried to interpret a buffer view which does not contain vertex or index data as a vertex or index array while loading a GLTF \'$path\'.', .warning);
          return null;
        }
        cache = bufferViewIndexToGpuBuffer[index] = Buffer(target);
        cache.bind();
        cache.write(bytes.buffer.asUint8List(byteOffset, byteLength).toJS, GL.STATIC_DRAW);
      } else {
        cache.bind();
      }
      return cache;
    }

    final rootNode = Node(name: rootName);
    final Map<int, Node> nodeIndexToNode = {
      -1: rootNode,
    };

    final nodeStack = [...rootNodeIndices.map((i) => (i, -1))];
    for (final (index, parent) in nodeStack) {
      final node = nodes[index];

      final name = node['name'] as String? ?? '_$index';

      final childrenIndices = node['children'] as List<dynamic>?;
      if (childrenIndices != null && childrenIndices.isNotEmpty) {
        nodeStack.addAll(childrenIndices.map((i) => (i, index)));
      }

      var translation = _listToVector3(node['translation'] as List<dynamic>? ?? [0.0, 0.0, 0.0]);
      var rotation = _listToQuaternion(node['rotation'] as List<dynamic>? ?? [0.0, 0.0, 0.0, 1.0]);
      var scale = _listToVector3(node['scale'] as List<dynamic>? ?? [1.0, 1.0, 1.0]);
      final flatMatrix = node['matrix'] as List<dynamic>?;
      if (flatMatrix != null) {
        final matrix = Matrix4.fromList(flatMatrix.cast());
        matrix.decompose(translation, rotation, scale);
      }

      final result = Node(
        name: name,
        pos: translation,
        rot: rotation,
        scale: scale,
      );

      final meshIndex = node['mesh'];
      if (meshIndex != null) {
        final mesh = meshes[meshIndex];
        final primitives = mesh['primitives'] as List<dynamic>;
        for (final primitive in primitives) {
          final meshVao = gl.createVertexArray()!;
          gl.bindVertexArray(meshVao);
          int meshTopology;
          var meshOffset = 0;
          var meshCount = 0;
          int? meshIndexType;

          int? minCount;
          final attributes = primitive['attributes'] as Map<String, dynamic>;
          for (final entry in attributes.entries) {
            final attribute = entry.key;
            final accessorIndex = entry.value;

            final attributeInfo = _attributeInfo[attribute];
            if (attributeInfo == null) {
              Logger.log('The GLTF loader is skipping an unsupported vertex attribute type \'$attribute\' in \'$path\'.', .info);
              continue;
            }

            final index = attributeInfo.$1;

            final accessor = accessors[accessorIndex];
            final bufferViewIndex = accessor['bufferView'];
            final byteOffset = accessor['byteOffset'] as int? ?? 0;
            final componentSize = _componentSizes[accessor['type']] ?? attributeInfo.$2;
            final componentType = accessor['componentType'];
            final normalized = accessor['normalized'] ?? false;
            final count = accessor['count'] as int;
            if (minCount == null || count < minCount) minCount = count;
            // TODO: sparse

            final bufferView = bufferViews[bufferViewIndex];
            final byteStride = bufferView['byteStride'] as int? ?? 0;

            final gpuBuffer = await getAndBindGpuBufferFromView(bufferViewIndex);
            if (gpuBuffer == null) continue;

            gl.enableVertexAttribArray(index);
            gl.vertexAttribPointer(index, componentSize, componentType, normalized, byteStride, byteOffset);
          }
          meshCount = minCount ?? 0;

          final indicesAccessorIndex = primitive['indices'] as int?;
          if (indicesAccessorIndex != null) {
            final accessor = accessors[indicesAccessorIndex];
            final bufferViewIndex = accessor['bufferView'];
            meshOffset = accessor['byteOffset'] as int? ?? 0;
            meshIndexType = accessor['componentType'];
            meshCount = accessor['count'] as int;
            // TODO: sparse

            final gpuBuffer = await getAndBindGpuBufferFromView(bufferViewIndex);
            if (gpuBuffer == null) continue;
          }

          // final material = primitive['material'];
          // TODO: material

          meshTopology = primitive['mode'] as int? ?? GL.TRIANGLES;

          result.addComponent(
            MeshComponent(
              mesh: _GLTFMeshPrimitive._(
                vao: meshVao,
                topology: meshTopology,
                offset: meshOffset,
                count: meshCount,
                indexType: meshIndexType,
              ),
            ),
          );
        }
      }

      nodeIndexToNode[index] = result;
      nodeIndexToNode[parent]!.addChild(result);
    }

    return GLTF(
      root: rootNode,
      copyright: copyright,
      generator: generator,
    );
  }
}
