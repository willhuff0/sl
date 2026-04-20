import 'package:sl_engine/components/physics_component.dart';
import 'package:sl_engine/gl/debug_draw.dart';
import 'package:vector_math/vector_math.dart';
import 'package:oimo_physics/oimo_physics.dart' as oimo;

class Physics {
  static final _entities = <PhysicsComponent, oimo.RigidBody>{};

  static late oimo.World _world;

  static void init() {
    _world = oimo.World();
  }

  static void clear() {
    init();
    _entities.clear();
  }

  static double? _accumulator;
  static void tick(double dt) {
    if (_accumulator == null) {
      _accumulator = 0.0;
    } else {
      _accumulator = _accumulator! + dt;
    }

    while (_accumulator! > _world.timeStep) {
      _world.step();
      _accumulator = _accumulator! - _world.timeStep;
    }

    for (final entity in _entities.entries) {
      final component = entity.key;
      final rigidBody = entity.value;

      component.node.wPos = rigidBody.position;
      component.node.wRot = Quaternion.fromRotation(rigidBody.rotation).inverted();
    }
  }

  static void addEntity(PhysicsComponent entity) {
    _entities[entity] = _world.add(entity.config) as oimo.RigidBody;
  }

  static void removeEntity(PhysicsComponent entity) {
    final rigidBody = _entities.remove(entity)!;
    _world.removeRigidBody(rigidBody);
  }

  static void drawDebugShapes() {
    for (final entity in _entities.entries) {
      final rigidBody = entity.value;

      final aabb = rigidBody.shapes!.aabb;
      final center = (aabb.max + aabb.min) / 2.0;
      final size = aabb.max - aabb.min;

      final rotation = Quaternion.fromRotation(rigidBody.rotation).inverted();

      DebugDraw.drawBox3D(
        center: center,
        size: size,
        rotation: rotation,
        color: Vector4(1.0, 0.0, 0.0, 0.2),
      );
    }
  }
}
