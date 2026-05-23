import 'dart:js_interop';
import 'dart:math';
import 'dart:typed_data';

import 'package:sl_engine/gl/gl.dart';
import 'package:sl_engine/gl/mesh.dart';
import 'package:sl_engine/gl/shader.dart';
import 'package:sl_engine/utils/resource_loader.dart';
import 'package:sl_engine/utils/sl_wasm.dart';
import 'package:vector_math/vector_math.dart';
import 'package:web/web.dart' as web;

final _cubeMesh = CubeMesh();

class HDRI {
  final web.WebGLTexture texture;
  final Vector2Int size;

  HDRI._(this.texture, this.size);

  factory HDRI.fromPixels(Float32List data, int width, int height) {
    final texture = gl.createTexture()!;
    gl.bindTexture(GL.TEXTURE_2D, texture);
    gl.texImage2D(GL.TEXTURE_2D, 0, GL.RGB16F, width.toJS, height.toJS, 0.toJS, GL.RGB, GL.FLOAT, data.toJS);

    gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE);
    gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE);
    gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR);
    gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR);

    return HDRI._(texture, (width, height));
  }

  static Future<HDRI?> loadFromHdr(String path, {ResourceLoader? resourceLoader}) async {
    resourceLoader = BuiltInResourceLoader();

    final encodedBytes = await resourceLoader.loadBytes(path);
    if (encodedBytes == null) return null;

    final (hdriPixels, width, height, _) = (await getStbImage()).loadfFromMemory(encodedBytes, channels: 3);
    return HDRI.fromPixels(hdriPixels, width, height);
  }
}

class CubeMap {
  final web.WebGLTexture texture;
  final int faceSize;
  final int mipLevelCount;

  CubeMap._({
    required this.texture,
    required this.faceSize,
    required this.mipLevelCount,
  });

  static final _captureProjMat = makePerspectiveMatrix(radians(90.0), 1.0, 0.1, 10.0);
  static final _captureViewMats = [
    makeViewMatrix(Vector3.zero(), Vector3(1.0, 0.0, 0.0), Vector3(0.0, -1.0, 0.0)),
    makeViewMatrix(Vector3.zero(), Vector3(-1.0, 0.0, 0.0), Vector3(0.0, -1.0, 0.0)),
    makeViewMatrix(Vector3.zero(), Vector3(0.0, 1.0, 0.0), Vector3(0.0, 0.0, 1.0)),
    makeViewMatrix(Vector3.zero(), Vector3(0.0, -1.0, 0.0), Vector3(0.0, 0.0, -1.0)),
    makeViewMatrix(Vector3.zero(), Vector3(0.0, 0.0, 1.0), Vector3(0.0, -1.0, 0.0)),
    makeViewMatrix(Vector3.zero(), Vector3(0.0, 0.0, -1.0), Vector3(0.0, -1.0, 0.0)),
  ];
  static final _captureViewProjMats = List<Matrix4>.generate(6, (i) => _captureProjMat * _captureViewMats[i]);
  static web.WebGLFramebuffer? _captureFramebuffer;
  static CubeMap _capture({required Shader shader, required int size, int mipLevelCount = 1, void Function(int mipLevel)? bindUniformsCallback}) {
    final cubeMap = gl.createTexture()!;
    gl.activeTexture(GL.TEXTURE1);
    gl.bindTexture(GL.TEXTURE_CUBE_MAP, cubeMap);
    gl.texStorage2D(GL.TEXTURE_CUBE_MAP, mipLevelCount, GL.RGBA16F, size, size);
    gl.texParameteri(GL.TEXTURE_CUBE_MAP, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE);
    gl.texParameteri(GL.TEXTURE_CUBE_MAP, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE);
    gl.texParameteri(GL.TEXTURE_CUBE_MAP, GL.TEXTURE_WRAP_R, GL.CLAMP_TO_EDGE);
    gl.texParameteri(GL.TEXTURE_CUBE_MAP, GL.TEXTURE_MIN_FILTER, mipLevelCount > 1 ? GL.LINEAR_MIPMAP_LINEAR : GL.LINEAR);
    gl.texParameteri(GL.TEXTURE_CUBE_MAP, GL.TEXTURE_MAG_FILTER, GL.LINEAR);

    _captureFramebuffer ??= gl.createFramebuffer()!;
    gl.bindFramebuffer(GL.FRAMEBUFFER, _captureFramebuffer);

    _cubeMesh.bind();

    for (var i = 0; i < mipLevelCount; i++) {
      final mipSize = (size * pow(0.5, i)).toInt();
      gl.viewport(0, 0, mipSize, mipSize);
      bindUniformsCallback?.call(i);

      for (var j = 0; j < 6; j++) {
        gl.framebufferTexture2D(GL.FRAMEBUFFER, GL.COLOR_ATTACHMENT0, GL.TEXTURE_CUBE_MAP_POSITIVE_X + j, cubeMap, i);
        gl.clearColor(0.0, 0.0, 0.0, 1.0);
        gl.clear(GL.COLOR_BUFFER_BIT);

        shader.setUniform('u_viewProjMat', _captureViewProjMats[j]);

        _cubeMesh.draw();
      }
    }

    _cubeMesh.unbind();

    gl.bindFramebuffer(GL.FRAMEBUFFER, defaultFramebuffer);
    return CubeMap._(
      texture: cubeMap,
      faceSize: size,
      mipLevelCount: mipLevelCount,
    );
  }

  static Shader? _equirectangularToCubemapShader;
  static Future<CubeMap> fromHdri(HDRI hdri) async {
    final size = hdri.size.$2;

    _equirectangularToCubemapShader ??= await () async {
      final equirectangularToCubemapShader = (await Shader.loadSeparate(
        'shaders/skybox/cubemap_capture',
        'shaders/skybox/equirectangular_to_cubemap',
      ))!;
      equirectangularToCubemapShader.bind();
      equirectangularToCubemapShader.setUniform('u_equirectangularMap', 0);
      return equirectangularToCubemapShader;
    }();
    _equirectangularToCubemapShader!.bind();

    gl.activeTexture(GL.TEXTURE0);
    gl.bindTexture(GL.TEXTURE_2D, hdri.texture);

    final cubeMap = _capture(
      shader: _equirectangularToCubemapShader!,
      size: size,
    );

    gl.bindTexture(GL.TEXTURE_CUBE_MAP, cubeMap.texture);
    gl.generateMipmap(GL.TEXTURE_CUBE_MAP);

    return cubeMap;
  }

  static Shader? _irradianceShader;
  Future<CubeMap> generateIrradianceMap({int size = 32}) async {
    _irradianceShader ??= await () async {
      final irradianceShader = (await Shader.loadSeparate(
        'shaders/skybox/cubemap_capture',
        'shaders/skybox/irradiance',
      ))!;
      irradianceShader.bind();
      irradianceShader.setUniform('u_cubeMap', 0);
      return irradianceShader;
    }();
    _irradianceShader!.bind();

    gl.activeTexture(GL.TEXTURE0);
    gl.bindTexture(GL.TEXTURE_CUBE_MAP, texture);

    return _capture(
      shader: _irradianceShader!,
      size: size,
    );
  }

  static Shader? _radianceShader;
  Future<CubeMap> generateRadianceMap({int size = 256}) async {
    final mipLevelCount = (log(size) / ln2).floor();

    _radianceShader ??= await () async {
      final radianceShader = (await Shader.loadSeparate(
        'shaders/skybox/cubemap_capture',
        'shaders/skybox/radiance',
      ))!;
      radianceShader.bind();
      radianceShader.setUniform('u_cubeMap', 0);
      return radianceShader;
    }();
    _radianceShader!.bind();
    _radianceShader!.setUniform('u_cubeMapResolution', faceSize.toDouble());

    gl.activeTexture(GL.TEXTURE0);
    gl.bindTexture(GL.TEXTURE_CUBE_MAP, texture);

    return _capture(
      shader: _radianceShader!,
      size: size,
      mipLevelCount: mipLevelCount,
      bindUniformsCallback: (mipLevel) {
        final roughness = mipLevel / (mipLevelCount - 1);
        _radianceShader!.setUniform('u_roughness', roughness);
      },
    );
  }

  void bind(int slot) {
    gl.activeTexture(GL.TEXTURE0 + slot);
    gl.bindTexture(GL.TEXTURE_CUBE_MAP, texture);
  }
}

class Skybox {
  static Shader? _skyboxShader;

  final CubeMap environmentMap;
  final CubeMap irradianceMap;
  final CubeMap radianceMap;

  Skybox._({
    required this.environmentMap,
    required this.irradianceMap,
    required this.radianceMap,
  });

  static Future<Skybox> fromHdri(HDRI hdri) async {
    _skyboxShader ??= await () async {
      final skyboxShader = (await Shader.load('shaders/skybox/skybox'))!;
      skyboxShader.bind();
      skyboxShader.setUniform('u_cubeMap', 0);
      return skyboxShader;
    }();

    final environmentMap = await CubeMap.fromHdri(hdri);
    final irradianceMap = await environmentMap.generateIrradianceMap();
    final radianceMap = await environmentMap.generateRadianceMap();
    return Skybox._(
      environmentMap: environmentMap,
      irradianceMap: irradianceMap,
      radianceMap: radianceMap,
    );
  }

  void bindIblMaps() {
    irradianceMap.bind(14);
    radianceMap.bind(15);
  }

  void draw() {
    gl.depthFunc(GL.LEQUAL);
    gl.depthMask(false);
    _skyboxShader!.bind();
    environmentMap.bind(0);
    _cubeMesh.bind();
    _cubeMesh.draw();
    _cubeMesh.unbind();
    gl.depthMask(true);
    gl.depthFunc(GL.LESS);
  }
}
