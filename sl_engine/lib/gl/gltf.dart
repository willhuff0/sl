import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:sl_engine/components/mesh_component.dart';
import 'package:sl_engine/gl/brdf_lut.dart';
import 'package:sl_engine/gl/buffer.dart';
import 'package:sl_engine/gl/gl.dart';
import 'package:sl_engine/gl/mesh.dart';
import 'package:path/path.dart' as p;
import 'package:sl_engine/gl/shader.dart';
import 'package:sl_engine/gl/texture.dart';
import 'package:sl_engine/logger.dart';
import 'package:sl_engine/node.dart';
import 'package:sl_engine/utils/renderer.dart';
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
  @override
  final Aabb3 bounds;

  _GLTFMeshPrimitive._({
    required this.vao,
    required this.topology,
    required this.offset,
    required this.count,
    required this.indexType,
    required this.bounds,
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

Vector4 _listToVector4(List<dynamic> list) {
  return Vector4(list[0], list[1], list[2], list[3]);
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
  'TANGENT': (2, 4),
  'TEXCOORD_0': (3, 2),
};

class GLTF {
  static Shader? _shader;
  static BrdfLut? _brdfLut;

  final Node root;
  final String? copyright;
  final String? generator;
  final Aabb3? aabb;

  GLTF({
    required this.root,
    required this.copyright,
    required this.generator,
    this.aabb,
  });

  static Future<Shader> _loadShader() async {
    final shader = (await Shader.load('shaders/gltf/gltf'))!;
    shader.bind();
    shader.setUniform('u_baseColorTexture', 0);
    shader.setUniform('u_metallicRoughnessTexture', 1);
    shader.setUniform('u_normalTexture', 2);
    shader.setUniform('u_occlusionTexture', 3);

    shader.setUniform('u_ambientIntensity', 1.0);
    shader.setUniform('u_sunDir', Vector3(-0.5, 1.0, -0.5).normalized());
    // shader.setUniform('u_sunColor', Vector3(1.0, 1.0, 0.98));
    shader.setUniform('u_sunColor', Vector3.zero());

    return shader;
  }

  static Future<GLTF?> load(String path, {String? sceneName, ResourceLoader? resourceLoader}) async {
    resourceLoader ??= BuiltInResourceLoader.get();
    _shader ??= await _loadShader();
    _brdfLut ??= await BrdfLut.generate();

    final directory = p.dirname(path);
    final extension = p.extension(path);

    Uint8List? glbBuffer;

    Map<String, dynamic> json;
    switch (extension) {
      case '.glb':
        final response = await resourceLoader.loadBytes(path);
        if (response == null) return null;
        final buffer = response.buffer;
        final bytes = buffer.asByteData();

        var offset = -4;

        final magic = bytes.getUint32(offset += 4, Endian.little);
        if (magic != 0x46546C67) {
          Logger.log('Tried to load a GLTF \'$path\' which is malformed (incorrect magic number).', .warning);
          return null;
        }

        final version = bytes.getUint32(offset += 4, Endian.little);
        if (version != 2) {
          Logger.log('Tried to load a GLTF \'$path\' with unsupported version \'$version\'. Use version \'2.0\'.', .warning);
          return null;
        }

        final fileLength = bytes.getUint32(offset += 4, Endian.little);

        final jsonChunkLength = bytes.getUint32(offset += 4, Endian.little);
        final jsonChunkType = bytes.getUint32(offset += 4, Endian.little);
        if (jsonChunkType != 0x4E4F534A) {
          Logger.log('Tried to load a GLTF \'$path\' which is malformed (first chunk is not json).', .warning);
          return null;
        }

        final jsonChunkData = buffer.asUint8List(offset + 4, jsonChunkLength);
        final jsonChunkText = utf8.decode(jsonChunkData);
        json = jsonDecode(jsonChunkText);

        offset += jsonChunkLength;

        if (offset + 4 >= fileLength - 1) {
          // binary chunk not present
          break;
        }

        final binaryChunkLength = bytes.getUint32(offset += 4, Endian.little);
        final binaryChunkType = bytes.getUint32(offset += 4, Endian.little);
        if (binaryChunkType != 0x004E4942) {
          Logger.log('Tried to load a GLTF \'$path\' which is malformed (second chunk is not binary).', .warning);
          return null;
        }

        offset += 4;
        glbBuffer = buffer.asUint8List(offset, binaryChunkLength);
        break;
      case '.gltf':
        final response = await resourceLoader.loadString(path);
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

    final nodes = json['nodes'] as List<dynamic>? ?? [];
    final meshes = json['meshes'] as List<dynamic>? ?? [];
    final accessors = json['accessors'] as List<dynamic>? ?? [];
    final bufferViews = json['bufferViews'] as List<dynamic>? ?? [];
    final buffers = json['buffers'] as List<dynamic>? ?? [];
    final images = json['images'] as List<dynamic>? ?? [];
    final samplers = json['samplers'] as List<dynamic>? ?? [];
    final textures = json['textures'] as List<dynamic>? ?? [];
    final materials = json['materials'] as List<dynamic>? ?? [];

    final bufferIndexToBytes = <int, Uint8List>{};
    final bufferViewIndexToGpuBuffer = <int, Buffer>{};

    final imageIndexToGpuImage = <int, Image>{};
    final textureIndexToGpuTexture = <int, Texture>{};
    final materialIndexToGpuMaterial = <int, Material>{};

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
            final bytes = await resourceLoader!.loadBytes(resolved);
            if (bytes == null) return null;
            cache = bufferIndexToBytes[index] = bytes;
          }
        }
      }
      return cache;
    }

    Future<Buffer?> getAndBindGpuBufferFromView(int index, [int? inferredTarget]) async {
      var cache = bufferViewIndexToGpuBuffer[index];
      if (cache == null) {
        final bufferView = bufferViews[index];
        final byteOffset = bufferView['byteOffset'] as int? ?? 0;
        final byteLength = bufferView['byteLength'] as int;
        final bufferIndex = bufferView['buffer'] as int;
        final bytes = await getBufferBytes(bufferIndex);
        if (bytes == null) return null;
        final target = bufferView['target'] as int? ?? inferredTarget;
        if (target == null) {
          Logger.log('Tried to interpret a buffer view which does not contain vertex or index data as a vertex or index array while loading a GLTF \'$path\'.', .warning);
          return null;
        }
        cache = bufferViewIndexToGpuBuffer[index] = Buffer(target);
        cache.bind();
        cache.write(bytes.buffer.asUint8List(bytes.offsetInBytes + byteOffset, byteLength).toJS, GL.STATIC_DRAW);
      } else {
        cache.bind();
      }
      return cache;
    }

    Future<Image?> getGpuImage(int index) async {
      var cache = imageIndexToGpuImage[index];
      if (cache == null) {
        final image = images[index] as Map<String, dynamic>;

        final uriString = image['uri'] as String?;
        if (uriString != null) {
          final uri = Uri.parse(uriString);
          if (uri.data != null) {
            final result = await Image.loadFromMemory(uri.data!.contentAsBytes());
            if (result == null) {
              Logger.log('Failed to load an image from a data uri while loading a GLTF \'$path\'.', .warning);
              return null;
            }
            cache = imageIndexToGpuImage[index] = result;
          } else if (uri.isScheme('HTTP') || uri.isScheme('HTTPS')) {
            final response = await http.get(uri);
            if (response.statusCode != 200) {
              Logger.log('Failed to load an image over the network while loading a GLTF \'$path\'. HTTP GET to \'$uri\' returned status code ${response.statusCode}.', .warning);
              return null;
            }
            final result = await Image.loadFromMemory(response.bodyBytes);
            if (result == null) {
              Logger.log('Failed to load an image over the network while loading a GLTF \'$path\'.', .warning);
              return null;
            }
            cache = imageIndexToGpuImage[index] = result;
          } else {
            final resolved = p.join(directory, uri.path);
            final bytes = await resourceLoader!.loadBytes(resolved);
            if (bytes == null) return null;
            final result = await Image.loadFromMemory(bytes);
            if (result == null) {
              Logger.log('Failed to load an image from relative path while loading a GLTF \'$path\'.', .warning);
              return null;
            }
            cache = imageIndexToGpuImage[index] = result;
          }
        } else {
          final bufferViewIndex = image['bufferView'] as int?;
          if (bufferViewIndex == null) {
            Logger.log('Tried to load a GLTF \'$path\' which is malformed (image missing any of uri or bufferView).', .warning);
            return null;
          }
          final bufferView = bufferViews[bufferViewIndex];
          final byteOffset = bufferView['byteOffset'] as int? ?? 0;
          final byteLength = bufferView['byteLength'] as int;
          final bufferIndex = bufferView['buffer'] as int;
          final bytes = await getBufferBytes(bufferIndex);
          if (bytes == null) return null;

          final result = await Image.loadFromMemory(bytes.buffer.asUint8List(bytes.offsetInBytes + byteOffset, byteLength));
          if (result == null) {
            Logger.log('Failed to load an image from bufferView while loading a GLTF \'$path\'.', .warning);
            return null;
          }
          cache = imageIndexToGpuImage[index] = result;
        }
      }
      return cache;
    }

    Future<Texture?> getGpuTexture(int index) async {
      var cache = textureIndexToGpuTexture[index];
      if (cache == null) {
        final texture = textures[index] as Map<String, dynamic>;

        final samplerIndex = texture['sampler'] as int?;
        final sampler = samplerIndex == null ? null : samplers[samplerIndex] as Map<String, dynamic>;
        final magFilter = sampler?['magFilter'] as int? ?? GL.LINEAR;
        final minFilter = sampler?['minFilter'] as int? ?? GL.LINEAR;
        final wrapS = sampler?['wrapS'] as int? ?? GL.REPEAT;
        final wrapT = sampler?['wrapT'] as int? ?? GL.REPEAT;

        final imageIndex = texture['source'] as int?;
        if (imageIndex == null) {
          Logger.log('Tried to load a GLTF \'$path\' which uses an unsupported alternative image source for texture $index.', .warning);
          return null;
        }
        final image = await getGpuImage(imageIndex);
        if (image == null) return null;

        cache = textureIndexToGpuTexture[index] = Texture(
          image: image,
          magFilter: magFilter,
          minFilter: minFilter,
          wrapS: wrapS,
          wrapT: wrapT,
        );
      }
      return cache;
    }

    Future<Material?> getGpuMaterial(int index) async {
      var cache = materialIndexToGpuMaterial[index];
      if (cache == null) {
        final material = index == -1 ? <String, dynamic>{} : materials[index] as Map<String, dynamic>;

        final baseColorFactor = _listToVector4(material['pbrMetallicRoughness']?['baseColorFactor'] as List<dynamic>? ?? [1.0, 1.0, 1.0, 1.0]);
        final metallicFactor = material['pbrMetallicRoughness']?['metallicFactor'] as double? ?? 1.0;
        final roughnessFactor = material['pbrMetallicRoughness']?['roughnessFactor'] as double? ?? 1.0;
        final normalScale = material['normalTexture']?['scale'] as double? ?? 1.0;
        final occlusionStrength = material['occlusionTexture']?['strength'] as double? ?? 1.0;

        final Map<int, Texture> textures = {};
        Future<bool> addTexture(int slot, Map<String, dynamic>? textureInfo) async {
          if (textureInfo == null) return true;

          final textureIndex = textureInfo['index'] as int;
          final texCoord = textureInfo['texCoord'] as int?;

          if (texCoord != null && texCoord != 0) {
            Logger.log('Tried to load a GLTF \'$path\' which uses unsupported additional texture coordinate attributes.', .warning);
            return false;
          }

          final result = await getGpuTexture(textureIndex);
          if (result == null) return false;

          textures[slot] = result;
          return true;
        }

        if (!await addTexture(0, material['pbrMetallicRoughness']?['baseColorTexture'])) return null;
        if (!await addTexture(1, material['pbrMetallicRoughness']?['metallicRoughnessTexture'])) return null;
        if (!await addTexture(2, material['normalTexture'])) return null;
        if (!await addTexture(3, material['occlusionTexture'])) return null;

        cache = materialIndexToGpuMaterial[index] = Material(
          shader: _shader!,
          uniforms: {
            'u_baseColorFactor': baseColorFactor,
            'u_metallicFactor': metallicFactor,
            'u_roughnessFactor': roughnessFactor,
            'u_normalScale': normalScale,
            'u_occlusionStrength': occlusionStrength,
            'u_hasBaseColorTexture': textures.containsKey(0),
            'u_hasMetallicRoughnessTexture': textures.containsKey(1),
            'u_hasNormalTexture': textures.containsKey(2),
            'u_hasOcclusionTexture': textures.containsKey(3),
          },
          textures: textures,
        );
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
          var bounds = Aabb3();

          final attributes = primitive['attributes'] as Map<String, dynamic>;
          for (final entry in attributes.entries) {
            final attribute = entry.key;
            final accessorIndex = entry.value;

            final attributeInfo = _attributeInfo[attribute];
            if (attributeInfo == null) {
              Logger.log('Skipping an unsupported vertex attribute type \'$attribute\' in \'$path\'.', .info);
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

            if (attribute == 'POSITION') {
              final min = accessor['min'] as List<dynamic>?;
              final max = accessor['max'] as List<dynamic>?;
              if (min != null && max != null) {
                bounds = Aabb3.minMax(_listToVector3(min), _listToVector3(max));
              } else {
                Logger.log('Tried to load a GLTF \'$path\' which is malformed (min/max missing for POSITION attribute).', .info);
              }
            }

            final bufferView = bufferViews[bufferViewIndex];
            final byteStride = bufferView['byteStride'] as int? ?? 0;

            final gpuBuffer = await getAndBindGpuBufferFromView(bufferViewIndex, GL.ARRAY_BUFFER);
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

            final gpuBuffer = await getAndBindGpuBufferFromView(bufferViewIndex, GL.ELEMENT_ARRAY_BUFFER);
            if (gpuBuffer == null) continue;
          }

          final materialIndex = primitive['material'] as int?;
          Material? material;
          if (materialIndex != null) {
            material = await getGpuMaterial(materialIndex);
          }
          material ??= (await getGpuMaterial(-1))!;

          meshTopology = primitive['mode'] as int? ?? GL.TRIANGLES;

          result.addComponent(
            MeshComponent(
              material: material,
              mesh: _GLTFMeshPrimitive._(
                vao: meshVao,
                topology: meshTopology,
                offset: meshOffset,
                count: meshCount,
                indexType: meshIndexType,
                bounds: bounds,
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
