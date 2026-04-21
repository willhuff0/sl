import 'dart:js_interop';

import 'package:sl_engine/gl/gl.dart';
import 'package:sl_engine/logger.dart';
import 'package:sl_engine/utils/resource_loader.dart';
import 'package:vector_math/vector_math.dart';
import 'package:web/web.dart';
import 'package:path/path.dart' as p;

final Map<String, WebGLShader> _cache = {};

GLenum _inferShaderType(String path) {
  return switch (p.extension(path)) {
    '.vert' => GL.VERTEX_SHADER,
    '.frag' => GL.FRAGMENT_SHADER,
    _ => throw Exception('Couldn\'t infer shader type of \'$path\''),
  };
}

Future<WebGLShader?> _loadShader(String path, [GLenum? type]) async {
  {
    var cacheValue = _cache[path];
    if (cacheValue != null) return cacheValue;
  }

  final shader = gl.createShader(type ?? _inferShaderType(path));
  if (shader == null) return null;

  final source = await BuiltInResourceLoader.get().loadString(path);
  if (source == null) return null;
  gl.shaderSource(shader, source);

  gl.compileShader(shader);
  if (!gl.getShaderParameter(shader, GL.COMPILE_STATUS).isTruthy.toDart) {
    final infoLog = gl.getShaderInfoLog(shader);
    Logger.log('Shader compile error ($path):\n$infoLog', .error);
    return null;
  }

  return shader;
}

class _Uniform {
  final WebGLUniformLocation location;
  final String name;
  final int size;
  final int type;

  _Uniform({
    required this.location,
    required this.name,
    required this.size,
    required this.type,
  });
}

Map<String, _Uniform> _lookupUniforms(WebGLProgram program) {
  final result = <String, _Uniform>{};

  final count = (gl.getProgramParameter(program, GL.ACTIVE_UNIFORMS) as JSNumber).toDartInt;

  final blockIndices = (gl.getActiveUniforms(program, List.generate(count, (i) => i).jsify() as JSArray<JSNumber>, GL.UNIFORM_BLOCK_INDEX) as JSArray<JSNumber>).toDart;

  for (var i = 0; i < count; i++) {
    if (blockIndices[i].toDartInt != -1) continue;

    final info = gl.getActiveUniform(program, i)!;
    final location = gl.getUniformLocation(program, info.name)!;

    result[info.name] = _Uniform(
      location: location,
      name: info.name,
      size: info.size,
      type: info.type,
    );
  }

  return result;
}

class _UniformTypeInfo {
  final String name;
  final Set<Type> acceptedTypes;
  final dynamic setter;

  _UniformTypeInfo(this.name, this.acceptedTypes, this.setter);
}

final _uniformTypeInfos = {
  // float
  GL.FLOAT: _UniformTypeInfo('float (dart double)', {double, int}, (location, num value) => gl.uniform1f(location, value)),
  GL.FLOAT_VEC2: _UniformTypeInfo('vec2', {Vector2}, (location, Vector2 value) => gl.uniform2f(location, value.x, value.y)),
  GL.FLOAT_VEC3: _UniformTypeInfo('vec3', {Vector3}, (location, Vector3 value) => gl.uniform3f(location, value.x, value.y, value.z)),
  GL.FLOAT_VEC4: _UniformTypeInfo('vec4', {Vector4}, (location, Vector4 value) => gl.uniform4f(location, value.x, value.y, value.z, value.w)),
  // int
  GL.INT: _UniformTypeInfo('int', {int}, (location, int value) => gl.uniform1i(location, value)),
  GL.INT_VEC2: _UniformTypeInfo('ivec2', {Vector2Int}, (location, Vector2Int value) => gl.uniform2i(location, value.$1, value.$2)),
  GL.INT_VEC3: _UniformTypeInfo('ivec3', {Vector3Int}, (location, Vector3Int value) => gl.uniform3i(location, value.$1, value.$2, value.$3)),
  GL.INT_VEC4: _UniformTypeInfo('ivec4', {Vector4Int}, (location, Vector4Int value) => gl.uniform4i(location, value.$1, value.$2, value.$3, value.$4)),
  // bool
  GL.BOOL: _UniformTypeInfo('bool', {bool}, (location, bool value) => gl.uniform1i(location, value ? 1 : 0)),
  GL.BOOL_VEC2: _UniformTypeInfo('vec2bool', {Vector2Bool}, (location, Vector2Bool value) => gl.uniform2i(location, value.$1 ? 1 : 0, value.$2 ? 1 : 0)),
  GL.BOOL_VEC3: _UniformTypeInfo('vec3bool', {Vector3Bool}, (location, Vector3Bool value) => gl.uniform3i(location, value.$1 ? 1 : 0, value.$2 ? 1 : 0, value.$3 ? 1 : 0)),
  GL.BOOL_VEC4: _UniformTypeInfo('vec4bool', {Vector4Bool}, (location, Vector4Bool value) => gl.uniform4i(location, value.$1 ? 1 : 0, value.$2 ? 1 : 0, value.$3 ? 1 : 0, value.$3 ? 1 : 0)),
  // matrix
  GL.FLOAT_MAT2: _UniformTypeInfo('mat2', {Matrix2}, (location, Matrix2 value) => gl.uniformMatrix2fv(location, false, value.storage.toJS)),
  GL.FLOAT_MAT3: _UniformTypeInfo('mat3', {Matrix3}, (location, Matrix3 value) => gl.uniformMatrix3fv(location, false, value.storage.toJS)),
  GL.FLOAT_MAT4: _UniformTypeInfo('mat4', {Matrix4}, (location, Matrix4 value) => gl.uniformMatrix4fv(location, false, value.storage.toJS)),
  // sampler
  GL.SAMPLER_2D: _UniformTypeInfo('Sampler 2D (Texture Binding Index)', {int}, (location, int value) => gl.uniform1i(location, value)),
  GL.SAMPLER_CUBE: _UniformTypeInfo('Sampler Cube (Texture Binding Index)', {int}, (location, int value) => gl.uniform1i(location, value)),
  GL.SAMPLER_2D_ARRAY: _UniformTypeInfo('Sampler 2D Array (Texture Binding Index)', {int}, (location, int value) => gl.uniform1i(location, value)),
  GL.SAMPLER_2D_ARRAY_SHADOW: _UniformTypeInfo('Sampler 2D Array Shadow (Texture Binding Index)', {int}, (location, int value) => gl.uniform1i(location, value)),
  // unsigned int
  GL.UNSIGNED_INT: _UniformTypeInfo('uint', {int}, (location, int value) => gl.uniform1ui(location, value)),
  GL.UNSIGNED_INT_VEC2: _UniformTypeInfo('uvec2', {Vector2Int}, (location, Vector2Int value) => gl.uniform2ui(location, value.$1, value.$2)),
  GL.UNSIGNED_INT_VEC3: _UniformTypeInfo('uvec3', {Vector3Int}, (location, Vector3Int value) => gl.uniform3ui(location, value.$1, value.$2, value.$3)),
  GL.UNSIGNED_INT_VEC4: _UniformTypeInfo('uvec4', {Vector4Int}, (location, Vector4Int value) => gl.uniform4ui(location, value.$1, value.$2, value.$3, value.$4)),
};

class Shader {
  final WebGLProgram _program;
  late final Map<String, _Uniform> _uniforms;

  Shader(this._program) {
    _uniforms = _lookupUniforms(_program);

    tryBindUniformBlock('SL', 0);
    tryBindUniformBlock('Renderer', 1);
    tryBindUniformBlock('DirectionalLight', 2);

    bind();
    trySetUniform('u_cascadeShadowMap', 13);
    trySetUniform('u_irradianceMap', 14);
    trySetUniform('u_prefilterMap', 15);
  }

  static Future<Shader?> load(String pathWithoutExtension) {
    pathWithoutExtension = p.withoutExtension(pathWithoutExtension);
    return loadSeparate('$pathWithoutExtension.vert', '$pathWithoutExtension.frag');
  }

  static Future<Shader?> loadSeparate(String vertPath, String fragPath) async {
    if (p.extension(vertPath).isEmpty) vertPath = '$vertPath.vert';
    if (p.extension(fragPath).isEmpty) fragPath = '$fragPath.frag';

    final vert = await _loadShader(vertPath, GL.VERTEX_SHADER);
    final frag = await _loadShader(fragPath, GL.FRAGMENT_SHADER);
    if (vert == null || frag == null) return null;

    final program = gl.createProgram();
    if (program == null) return null;
    gl.attachShader(program, vert);
    gl.attachShader(program, frag);
    gl.linkProgram(program);
    gl.detachShader(program, vert);
    gl.detachShader(program, frag);

    if (!gl.getProgramParameter(program, GL.LINK_STATUS).isTruthy.toDart) {
      final infoLog = gl.getProgramInfoLog(program);
      Logger.log('Shader program link error ($vertPath, $fragPath):\n$infoLog', .error);
      return null;
    }

    return Shader(program);
  }

  void bind() {
    gl.useProgram(_program);
  }

  void unbind() {
    gl.useProgram(null);
  }

  void setUniform(String name, dynamic value) {
    final uniform = _uniforms[name];
    if (uniform == null) {
      Logger.log('Tried to assign uniform \'$name\' which doesn\'t exist in the shader.', .warning);
      return;
    }

    final typeInfo = _uniformTypeInfos[uniform.type];
    if (typeInfo == null) {
      throw Exception('Unsupported uniform type!');
    }

    final valueRuntimeType = value.runtimeType;
    if (!typeInfo.acceptedTypes.contains(valueRuntimeType)) {
      Logger.log(
        'Tried to assign $value ($valueRuntimeType) to uniform \'${uniform.name}\' which has type ${typeInfo.name}',
        .warning,
      );
      return;
    }

    typeInfo.setter(uniform.location, value);
  }

  bool trySetUniform(String name, dynamic value) {
    if (!_uniforms.containsKey(name)) return false;
    setUniform(name, value);
    return true;
  }

  void bindUniformBlock(String name, int binding) {
    if (!tryBindUniformBlock(name, binding)) {
      Logger.log('Tried to bind uniform block \'$name\', which doesn\'t exist in the shader, to binding $binding.');
    }
  }

  bool tryBindUniformBlock(String name, int binding) {
    final index = gl.getUniformBlockIndex(_program, name);
    if (index == GL.INVALID_INDEX) return false;
    gl.uniformBlockBinding(_program, index, binding);
    return true;
  }
}
