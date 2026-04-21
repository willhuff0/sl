import 'dart:math' as math;
import 'package:sl_engine/components/mesh_component.dart';
import 'package:sl_engine/gl/gltf.dart';
import 'package:sl_engine/node.dart';
import 'package:sl_engine/utils/renderer.dart';
import 'package:vector_math/vector_math.dart';

class _AvatarState {
  Vector3 position;
  Quaternion orientation;
  Vector4 color;
  Vector3 velocity = Vector3.zero();

  _AvatarState({
    required this.position,
    required this.orientation,
    required this.color,
  });
}

class Avatars {
  static late final Node _avatarNode;
  static const double smoothTime = 0.4;
  static const double maxSpeed = double.infinity;

  static Future<void> init() async {
    _avatarNode = (await GLTF.load('models/Avatar.glb'))!.root;
  }

  static var _targetViews = <int, (Vector3 position, Quaternion orientation, Vector4 color)>{};
  static final _currentViews = <int, _AvatarState>{};

  static void setRemoteViews(Map<int, (Vector3 position, Quaternion orientation, Vector4 color)> remoteViews) {
    _targetViews = remoteViews;
  }

  static (double, double) _smoothDamp(double current, double target, double currentVelocity, double smoothTime, double maxSpeed, double deltaTime) {
    smoothTime = math.max(0.0001, smoothTime);
    double num = 2.0 / smoothTime;
    double num2 = num * deltaTime;
    double num3 = 1.0 / (1.0 + num2 + 0.48 * num2 * num2 + 0.235 * num2 * num2 * num2);
    double num4 = current - target;
    double num5 = target;
    double num6 = maxSpeed * smoothTime;
    num4 = num4.clamp(-num6, num6);
    target = current - num4;
    double num7 = (currentVelocity + num * num4) * deltaTime;
    currentVelocity = (currentVelocity - num * num7) * num3;
    double num8 = target + (num4 + num7) * num3;
    if ((num5 - current > 0.0) == (num8 > num5)) {
      num8 = num5;
      currentVelocity = (num8 - num5) / deltaTime;
    }
    return (num8, currentVelocity);
  }

  static void tick(double time, double dt) {
    // Remove disconnected avatars
    _currentViews.removeWhere((id, _) => !_targetViews.containsKey(id));

    // Update active avatars
    for (final entry in _targetViews.entries) {
      final id = entry.key;
      final target = entry.value;

      if (!_currentViews.containsKey(id)) {
        _currentViews[id] = _AvatarState(
          position: target.$1.clone(),
          orientation: target.$2.clone(),
          color: target.$3.clone(),
        );
        continue;
      }

      final current = _currentViews[id]!;

      // Smooth damp position
      final x = _smoothDamp(current.position.x, target.$1.x, current.velocity.x, smoothTime, maxSpeed, dt);
      final y = _smoothDamp(current.position.y, target.$1.y, current.velocity.y, smoothTime, maxSpeed, dt);
      final z = _smoothDamp(current.position.z, target.$1.z, current.velocity.z, smoothTime, maxSpeed, dt);

      current.position.setValues(x.$1, y.$1, z.$1);
      current.velocity.setValues(x.$2, y.$2, z.$2);

      final t = math.min(1.0, dt * (1.0 / smoothTime));
      current.orientation = current.orientation + (target.$2 - current.orientation).scaled(t);
      current.orientation.normalize();

      current.color.setFrom(target.$3);
    }
  }

  static void draw() {
    for (final state in _currentViews.values) {
      _avatarNode.wPos = state.position;
      _avatarNode.wRot = state.orientation;
      // _avatarNode.children.first.components.whereType<MeshComponent>().first.material.uniforms['u_emissiveFactor'] = Vector3(state.color.x, state.color.y, state.color.z);
      _avatarNode.children.first.components.whereType<MeshComponent>().first.material.uniforms['u_baseColorFactor'] = state.color;
      Renderer.renderUnregisteredNode(_avatarNode);
    }
  }
}
