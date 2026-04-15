import 'dart:js_interop';
import 'dart:math';
import 'dart:typed_data';

import 'package:sl_engine/gl/gl.dart';
import 'package:sl_engine/gl/render_texture.dart';
import 'package:sl_engine/gl/shader.dart';
import 'package:sl_engine/gl/sl.dart';
import 'package:sl_engine/node.dart';
import 'package:sl_engine/utils/bounds.dart';
import 'package:sl_engine/utils/renderer.dart';
import 'package:vector_math/vector_math.dart';

Iterable<Vector3> _getCorners(Aabb3 bounds) sync* {
  yield Vector3(bounds.min.x, bounds.min.y, bounds.min.z);
  yield Vector3(bounds.max.x, bounds.min.y, bounds.min.z);
  yield Vector3(bounds.min.x, bounds.max.y, bounds.min.z);
  yield Vector3(bounds.max.x, bounds.max.y, bounds.min.z);
  yield Vector3(bounds.min.x, bounds.min.y, bounds.max.z);
  yield Vector3(bounds.max.x, bounds.min.y, bounds.max.z);
  yield Vector3(bounds.min.x, bounds.max.y, bounds.max.z);
  yield Vector3(bounds.max.x, bounds.max.y, bounds.max.z);
}

class ModelPreviewGenerator {
  static const _fov = 30.0 * degrees2Radians;
  static const _distancePadding = 1.0;

  late final Shader _previewShader;

  late final RenderTexture _outputTexture;

  ModelPreviewGenerator._();
  static Future<ModelPreviewGenerator> create() async {
    final previewGenerator = ModelPreviewGenerator._();

    previewGenerator._previewShader = (await Shader.load('shaders/preview/preview'))!;

    previewGenerator._outputTexture = RenderTexture(
      internalFormat: GL.RGBA8,
      format: GL.RGBA,
      type: GL.UNSIGNED_BYTE,
      depthFormat: GL.DEPTH_COMPONENT24,
    );

    return previewGenerator;
  }

  Uint8List generateModelPreview(Node node, {int size = 128}) {
    _outputTexture.resize(size, size);

    _previewShader.bind();
    _outputTexture.bindFramebuffer();
    gl.viewport(0, 0, size, size);
    gl.clearColor(0.0, 0.0, 0.0, 0.0);
    gl.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT);
    gl.blendFunc(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA);

    final forward = Vector3(-1.0, -0.6, -1.0)..normalize();
    final right = Vector3(0.0, 1.0, 0.0).cross(forward)..normalize();
    final up = forward.cross(right)..normalize();

    // 1. Calculate pristine local bounds by temporarily removing the root transform
    final rootPos = node.lPos.clone();
    final rootRot = node.lRot.clone();
    final rootScale = node.lScale.clone();

    node.lPos = Vector3.zero();
    node.lRot = Quaternion.identity();
    node.lScale = Vector3.all(1.0);

    final localBounds = Bounds.computeBounds(node);

    node.lPos = rootPos;
    node.lRot = rootRot;
    node.lScale = rootScale;

    // 2. Transform the 8 local AABB corners by the root's world matrix to get OBB corners
    final worldMat = node.getMatrix();
    final corners = _getCorners(localBounds).map((c) => worldMat.transformed3(c)).toList();

    var center = Vector3.zero();
    for (final c in corners) {
      center += c;
    }
    center /= 8.0;

    var radius = 0.0;
    for (final corner in corners) {
      radius = max(radius, corner.distanceTo(center));
    }

    final t = tan(_fov * 0.5);
    var distance = 0.0;
    for (final corner in corners) {
      final v = corner - center;

      final x = v.dot(right);
      final y = v.dot(up);
      final z = v.dot(forward);

      distance = max(distance, z + x.abs() / t);
      distance = max(distance, z + y.abs() / t);
    }
    distance *= _distancePadding;

    final viewPos = center - forward * distance;

    final nearPlane = max(0.01, distance - radius * 2.0);
    final farPlane = distance + radius * 2.0;

    final viewMat = makeViewMatrix(
      viewPos,
      center,
      Vector3(0.0, 1.0, 0.0),
    );
    final projMat = makePerspectiveMatrix(_fov, 1.0, nearPlane, farPlane);
    projMat[5] *= -1;
    SL.setUniforms(
      SLUniforms(
        viewProjMat: projMat * viewMat,
        viewMat: viewMat,
        viewPos: viewPos,
      ),
    );
    Renderer.renderUnregisteredNode(
      node,
    );

    node.enterScene();

    final pixels = JSUint8Array.withLength(size * size * 4);
    gl.readPixels(0, 0, size, size, GL.RGBA, GL.UNSIGNED_BYTE, pixels);
    final dartPixels = pixels.toDart;

    _outputTexture.unbindFramebuffer();
    gl.viewport(0, 0, canvas.width, canvas.height);
    gl.clearColor(0.0, 0.0, 0.0, 1.0);

    return dartPixels;
  }
}
