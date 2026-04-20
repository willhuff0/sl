import 'dart:js_interop';
import 'dart:math';
import 'dart:typed_data';

import 'package:sl_engine/editor/sl_editor.dart';
import 'package:sl_engine/gl/gl.dart';
import 'package:sl_engine/gl/render_texture.dart';
import 'package:sl_engine/gl/sl.dart';
import 'package:sl_engine/node.dart';
import 'package:sl_engine/utils/bounds.dart';
import 'package:sl_engine/utils/renderer.dart';
import 'package:vector_math/vector_math.dart';
import 'package:web/web.dart' as web;

const _defaultPreviewSize = 128;

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

  late final RenderTexture _outputTexture;

  late final web.OffscreenCanvas _offscreenCanvas;
  late final web.CanvasRenderingContext2D _offscreenContext;

  ModelPreviewGenerator._();
  static Future<ModelPreviewGenerator> create() async {
    final previewGenerator = ModelPreviewGenerator._();

    previewGenerator._outputTexture = RenderTexture(
      internalFormat: GL.RGBA8,
      format: GL.RGBA,
      type: GL.UNSIGNED_BYTE,
      depthFormat: GL.DEPTH_COMPONENT24,
    );

    previewGenerator._offscreenCanvas = web.OffscreenCanvas(_defaultPreviewSize, _defaultPreviewSize);
    previewGenerator._offscreenContext =
        previewGenerator._offscreenCanvas.getContext(
              '2d',
              {
                'alpha': true,
                'willReadFrequently': true,
              }.jsify(),
            )
            as web.CanvasRenderingContext2D;

    return previewGenerator;
  }

  Future<(Uint8List, String)> generateModelPreview(Node node, {int size = _defaultPreviewSize}) async {
    _outputTexture.resize(size, size);

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
    while (SLEditor.skybox == null) {
      await Future.delayed(Duration(milliseconds: 100));
    }
    SL.setUniforms(
      SLUniforms(
        viewProjMat: projMat * viewMat,
        projMat: projMat,
        viewMat: viewMat,
        viewPos: viewPos,
        radianceMipLevelCount: SLEditor.skybox!.radianceMap.mipLevelCount,
      ),
    );
    Renderer.renderUnregisteredNode(node);

    _offscreenCanvas.width = size;
    _offscreenCanvas.height = size;
    final imageData = _offscreenContext.createImageData(size.toJS, size);
    gl.readPixels(0, 0, size, size, GL.RGBA, GL.UNSIGNED_BYTE, imageData.data);
    _offscreenContext.putImageData(imageData, 0, 0);

    final blob = await _offscreenCanvas.convertToBlob(web.ImageEncodeOptions(type: 'image/webp')).toDart;
    final bytes = (await blob.arrayBuffer().toDart).toDart.asUint8List();

    _outputTexture.unbindFramebuffer();
    gl.viewport(0, 0, canvas.width, canvas.height);
    gl.clearColor(0.0, 0.0, 0.0, 1.0);

    return (bytes, blob.type);
  }
}
