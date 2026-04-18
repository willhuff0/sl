import 'dart:js_interop';
import 'dart:math';
import 'dart:typed_data';

import 'package:sl_engine/gl/buffer.dart';
import 'package:sl_engine/gl/gl.dart';
import 'package:sl_engine/gl/shader.dart';
import 'package:sl_engine/utils/renderer.dart';
import 'package:vector_math/vector_math.dart';
import 'package:web/web.dart' as web;

class _DirectionalLightUniforms {
  final List<Matrix4> lightSpaceViewProjMats;
  final List<double> cascadeDistances;

  final Vector3 direction;
  final Vector3 color;

  final double cameraZFar;

  final int cascadeCount;

  _DirectionalLightUniforms({
    required this.lightSpaceViewProjMats,
    required this.cascadeDistances,
    required this.direction,
    required this.color,
    required this.cameraZFar,
    required this.cascadeCount,
  });

  static final _data = ByteData(320);
  JSAny toJS() {
    var offset = 0;

    for (var i = 0; i < 4; i++) {
      final matrix = lightSpaceViewProjMats.elementAtOrNull(i) ?? Matrix4.identity();
      for (var j = 0; j < 16; j++) {
        _data.setFloat32(offset, matrix.storage[j], Endian.host);
        offset += 4;
      }
    }

    for (var i = 0; i < 4; i++) {
      _data.setFloat32(offset, cascadeDistances.elementAtOrNull(i) ?? 0.0, Endian.host);
      offset += 4;
    }

    _data.setFloat32(offset, direction.x, Endian.host);
    offset += 4;
    _data.setFloat32(offset, direction.y, Endian.host);
    offset += 4;
    _data.setFloat32(offset, direction.z, Endian.host);
    offset += 4;
    offset += 4;

    _data.setFloat32(offset, color.r, Endian.host);
    offset += 4;
    _data.setFloat32(offset, color.g, Endian.host);
    offset += 4;
    _data.setFloat32(offset, color.b, Endian.host);
    offset += 4;
    offset += 4;

    _data.setFloat32(offset, cameraZFar, Endian.host);
    offset += 4;

    _data.setUint32(offset, cascadeCount, Endian.host);
    offset += 4;

    return _data.buffer.asUint8List().toJS;
  }
}

class CascadeShadowMap {
  static Shader? _debugViewShader;

  final int size;
  final int cascades;
  final web.WebGLTexture texture;
  final web.WebGLFramebuffer framebuffer;

  CascadeShadowMap._({
    required this.size,
    required this.cascades,
    required this.texture,
    required this.framebuffer,
  });

  static Future<CascadeShadowMap> create(int size, int cascades) async {
    _debugViewShader ??= await () async {
      final debugViewShader = (await Shader.loadSeparate('shaders/fullscreen', 'shaders/shadows/depth_view'))!;
      debugViewShader.setUniform('u_depthMap', 13);
      return debugViewShader;
    }();

    gl.bindTexture(GL.TEXTURE_2D, null);
    gl.bindTexture(GL.TEXTURE_CUBE_MAP, null);

    final texture = gl.createTexture()!;
    gl.bindTexture(GL.TEXTURE_2D_ARRAY, texture);
    gl.texStorage3D(GL.TEXTURE_2D_ARRAY, 1, GL.DEPTH_COMPONENT32F, size, size, cascades);
    gl.texParameteri(GL.TEXTURE_2D_ARRAY, GL.TEXTURE_MIN_FILTER, GL.LINEAR);
    gl.texParameteri(GL.TEXTURE_2D_ARRAY, GL.TEXTURE_MAG_FILTER, GL.LINEAR);
    gl.texParameteri(GL.TEXTURE_2D_ARRAY, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE);
    gl.texParameteri(GL.TEXTURE_2D_ARRAY, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE);
    gl.texParameteri(GL.TEXTURE_2D_ARRAY, GL.TEXTURE_COMPARE_MODE, GL.COMPARE_REF_TO_TEXTURE);
    gl.texParameteri(GL.TEXTURE_2D_ARRAY, GL.TEXTURE_COMPARE_FUNC, GL.LEQUAL);

    final framebuffer = gl.createFramebuffer()!;
    gl.bindFramebuffer(GL.FRAMEBUFFER, framebuffer);
    gl.drawBuffers([GL.NONE.toJS].toJS);
    gl.readBuffer(GL.NONE);
    gl.bindFramebuffer(GL.FRAMEBUFFER, null);

    gl.bindTexture(GL.TEXTURE_2D_ARRAY, null);

    return CascadeShadowMap._(
      size: size,
      cascades: cascades,
      texture: texture,
      framebuffer: framebuffer,
    );
  }

  void bindFramebuffer() {
    gl.bindFramebuffer(GL.FRAMEBUFFER, framebuffer);
  }

  void bindCascadeToFramebuffer(int cascade) {
    gl.bindTexture(GL.TEXTURE_2D_ARRAY, texture);
    gl.framebufferTextureLayer(GL.FRAMEBUFFER, GL.DEPTH_ATTACHMENT, texture, 0, cascade);
  }

  void bindTexture(int slot) {
    gl.activeTexture(GL.TEXTURE0 + slot);
    gl.bindTexture(GL.TEXTURE_2D_ARRAY, texture);
  }

  void drawDebugView({int size = 512}) {
    _debugViewShader!.bind();
    _debugViewShader!.setUniform('u_cascades', cascades);
    bindTexture(13);
    gl.viewport(0, 0, size * 2, size * 2);
    gl.drawArrays(GL.TRIANGLES, 0, 6);
    gl.viewport(0, 0, canvas.width, canvas.height);
  }
}

class DirectionalLight {
  static Shader? _csmDepthShader;

  final Vector3 direction;
  final Vector3 color;

  final CascadeShadowMap shadowMap;
  final List<double> _cascadePortions;

  final Buffer uniformBuffer;

  DirectionalLight._({
    required this.direction,
    required this.color,
    required this.shadowMap,
    required List<double> cascadePortions,
    required this.uniformBuffer,
  }) : _cascadePortions = [0.0, ...cascadePortions] {
    assert(cascadePortions.length == shadowMap.cascades);
  }

  static Future<DirectionalLight> create({
    Vector3? direction,
    Vector3? color,
    int shadowMapSize = 4096,
    int shadowCascades = 4,
    List<double> cascadePortions = const [1.0 / 50.0, 1.0 / 20.0, 1.0 / 5.0, 1.0 / 2.0],
  }) async {
    shadowMapSize = min(shadowMapSize, (gl.getParameter(GL.MAX_TEXTURE_SIZE) as JSNumber).toDartInt);

    _csmDepthShader ??= (await Shader.load('shaders/shadows/csm_depth'))!;

    return DirectionalLight._(
      direction: direction ?? Vector3(20.0, 50, 20.0).normalized(),
      color: color ?? Vector3(1.0, 1.0, 0.98).scaled(10.0),
      shadowMap: await CascadeShadowMap.create(shadowMapSize, shadowCascades),
      cascadePortions: cascadePortions,
      uniformBuffer: Buffer(GL.UNIFORM_BUFFER),
    );
  }

  final _lightSpaceViewProjMats = <Matrix4>[];

  static List<Vector4> _getFrustumCornersWorldSpace(Matrix4 viewProjMat) {
    final invMat = viewProjMat.clone()..invert();

    final corners = <Vector4>[];
    for (var x = 0; x < 2; x++) {
      for (var y = 0; y < 2; y++) {
        for (var z = 0; z < 2; z++) {
          final point =
              invMat *
              Vector4(
                2.0 * x - 1.0,
                2.0 * y - 1.0,
                2.0 * z - 1.0,
                1.0,
              );

          corners.add(point / point.w);
        }
      }
    }

    return corners;
  }

  static Matrix4 _getCascadeViewProjMat({
    required Matrix4 cameraViewMat,
    required double fovRad,
    required double aspect,
    required double zNear,
    required double zFar,
    required Vector3 lightDir,
    required int shadowMapSize,
  }) {
    final projMat = makePerspectiveMatrix(fovRad, aspect, zNear, zFar);

    final frustumCorners = _getFrustumCornersWorldSpace(projMat * cameraViewMat);

    var center = Vector3.zero();
    for (final corner in frustumCorners) {
      center += corner.xyz;
    }
    center /= frustumCorners.length.toDouble();

    var radius = 0.0;
    for (final corner in frustumCorners) {
      radius = max(radius, (corner.xyz - center).length);
    }
    // Ceil the radius to steady small floating point variations
    radius = (radius * 16.0).ceilToDouble() / 16.0;

    var up = Vector3(0.0, 1.0, 0.0);
    if ((lightDir.normalized().y).abs() > 0.999) {
      up = Vector3(0.0, 0.0, 1.0);
    }
    final lightViewMat = makeViewMatrix(center + lightDir, center, up);

    var minX = -radius;
    var maxX = radius;
    var minY = -radius;
    var maxY = radius;
    var minZ = double.infinity;
    var maxZ = double.negativeInfinity;
    for (final corner in frustumCorners) {
      final cornerLightViewSpace = lightViewMat * corner;
      minZ = min(minZ, cornerLightViewSpace.z);
      maxZ = max(maxZ, cornerLightViewSpace.z);
    }

    final zMult = 10.0;
    if (minZ < 0) {
      minZ *= zMult;
    } else {
      minZ /= zMult;
    }
    if (maxZ < 0) {
      maxZ /= zMult;
    } else {
      maxZ *= zMult;
    }

    final lightProjMat = makeOrthographicMatrix(minX, maxX, minY, maxY, minZ, maxZ);

    final shadowMatrix = lightProjMat * lightViewMat;
    final shadowOrigin = Vector4(0.0, 0.0, 0.0, 1.0);
    final shadowOriginNDC = shadowMatrix * shadowOrigin;

    final shadowMapSizeD = shadowMapSize.toDouble();
    final shadowOriginScaled = shadowOriginNDC * (shadowMapSizeD / 2.0);

    final roundedOrigin = Vector4(
      shadowOriginScaled.x.roundToDouble(),
      shadowOriginScaled.y.roundToDouble(),
      shadowOriginScaled.z.roundToDouble(),
      shadowOriginScaled.w,
    );

    final roundOffset = roundedOrigin - shadowOriginScaled;
    roundOffset.scale(2.0 / shadowMapSizeD);
    roundOffset.z = 0.0;
    roundOffset.w = 0.0;

    lightProjMat.setColumn(3, lightProjMat.getColumn(3) + roundOffset);

    return lightProjMat * lightViewMat;
  }

  void regenerateLightSpaceMatrices({
    required Matrix4 cameraViewMat,
    required double cameraNear,
    required double cameraFar,
    required double fovRad,
    required double aspect,
  }) {
    final cascadeDistances = <double>[];

    _lightSpaceViewProjMats.clear();
    for (var cascade = 0; cascade < shadowMap.cascades; cascade++) {
      final zNear = cameraNear + (cameraFar - cameraNear) * _cascadePortions[cascade];
      final zFar = cameraNear + (cameraFar - cameraNear) * _cascadePortions[cascade + 1];

      cascadeDistances.add(zFar);
      _lightSpaceViewProjMats.add(
        _getCascadeViewProjMat(
          cameraViewMat: cameraViewMat,
          fovRad: fovRad,
          aspect: aspect,
          zNear: zNear,
          zFar: zFar,
          lightDir: direction,
          shadowMapSize: shadowMap.size,
        ),
      );
    }

    uniformBuffer.bind();
    uniformBuffer.write(
      _DirectionalLightUniforms(
        direction: direction,
        color: color,
        lightSpaceViewProjMats: _lightSpaceViewProjMats,
        cascadeDistances: cascadeDistances,
        cameraZFar: cameraFar,
        cascadeCount: shadowMap.cascades,
      ).toJS(),
      GL.DYNAMIC_DRAW,
    );
  }

  void bindUbo() {
    uniformBuffer.bind();
    uniformBuffer.bindToUniformBuffer(2);
  }

  void drawShadowMap() {
    gl.enable(GL.DEPTH_TEST);
    gl.depthMask(true);

    _csmDepthShader!.bind();

    gl.bindTexture(GL.TEXTURE_2D, null);
    gl.bindTexture(GL.TEXTURE_CUBE_MAP, null);
    shadowMap.bindFramebuffer();
    gl.viewport(0, 0, shadowMap.size, shadowMap.size);
    gl.cullFace(GL.FRONT);

    for (var cascade = 0; cascade < shadowMap.cascades; cascade++) {
      _csmDepthShader!.setUniform('u_viewProjMat', _lightSpaceViewProjMats[cascade]);

      shadowMap.bindCascadeToFramebuffer(cascade);

      gl.clear(GL.DEPTH_BUFFER_BIT);
      Renderer.renderAllCustomShader(
        bindUniformsCallback: (node) {
          _csmDepthShader!.setUniform('u_modelMat', node.getMatrix());
        },
      );
    }

    gl.bindTexture(GL.TEXTURE_2D_ARRAY, null);
    gl.bindFramebuffer(GL.FRAMEBUFFER, null);
    gl.viewport(0, 0, canvas.width, canvas.height);
    gl.cullFace(GL.BACK);
  }

  void bindShadowMap() {
    shadowMap.bindTexture(13);
  }
}
