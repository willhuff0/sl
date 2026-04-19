import 'package:sl_engine/node.dart';
import 'package:sl_engine/utils/bounds.dart';
import 'package:sl_engine/utils/physics.dart';

import 'package:oimo_physics/oimo_physics.dart' as oimo;
import 'package:vector_math/vector_math.dart';

class PhysicsComponent extends Component {
  final oimo.ObjectConfigure config;
  final bool move;

  PhysicsComponent({
    required this.config,
    this.move = true,
  });

  factory PhysicsComponent.fromSphere({required double radius, Vector3? pivot, bool move = true}) => PhysicsComponent(
    config: oimo.ObjectConfigure(
      shapes: [
        oimo.Sphere(
          oimo.ShapeConfig(
            relativePosition: pivot,
          ),
          radius,
        ),
      ],
      move: move,
      massPos: true,
    ),
  );

  factory PhysicsComponent.fromNodeBounds(Node node, {bool move = true}) => PhysicsComponent.fromLocalBounds(
    Bounds.computeLocalBounds(node),
    move: move,
  );

  factory PhysicsComponent.fromLocalBounds(Aabb3 bounds, {bool move = true}) {
    final size = bounds.max - bounds.min;
    final pivot = bounds.center;

    return PhysicsComponent(
      config: oimo.ObjectConfigure(
        shapes: [
          oimo.Box(
            oimo.ShapeConfig(
              relativePosition: pivot,
            ),
            size.x,
            size.y,
            size.z,
          ),
        ],
        move: move,
        massPos: true,
      ),
    );
  }

  @override
  void onEnable() {
    config.position = node.wPos;
    Physics.addEntity(this);
  }

  @override
  void onDisable() {
    Physics.removeEntity(this);
  }
}
