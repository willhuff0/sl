import 'package:sl_editor/client/state_tracker.dart';
import 'package:sl_engine/node.dart' as engine;
import 'package:sl_shared/sl_shared.dart';

final Map<engine.Node, Node> _engineNodeToTracker = {};

class Node extends StateTracked {
  final TrackedProperty<String> name = TrackedProperty('name', 'New Node');
  final TrackedProperty<List<UUID>> children = TrackedProperty('children', []);
  final TrackedProperty<(double, double, double)> lPos = TrackedProperty('lPos', (0.0, 0.0, 0.0));
  final TrackedProperty<(double, double, double, double)> lRot = TrackedProperty('lRot', (0.0, 0.0, 0.0, 1.0));
  final TrackedProperty<(double, double, double)> lScale = TrackedProperty('lScale', (1.0, 1.0, 1.0));

  final engine.Node engineNode;

  static ObjectClass get objectClass => 'node';

  static Node getTrackerForEngineNode(engine.Node node) {
    return _engineNodeToTracker[node]!;
  }

  static Node create() {
    final node = Node(generateUuid());
    node.createThis('node');
    return node;
  }

  Node(super.uuid) : engineNode = engine.Node(name: 'New Node') {
    _engineNodeToTracker[engineNode] = this;
  }

  @override
  void getDeltaFromNull(Delta builder) {
    super.getDeltaFromNull(builder);
    name.getDeltaFromNullRelToObject(builder);
    children.getDeltaFromNullRelToObject(builder);
    lPos.getDeltaFromNullRelToObject(builder);
    lRot.getDeltaFromNullRelToObject(builder);
    lScale.getDeltaFromNullRelToObject(builder);
  }

  @override
  void applyDelta(Delta delta) {
    super.applyDelta(delta);
    name.applyDeltaRelToObject(delta, effect: (newName) => engineNode.name = newName);
    children.applyDeltaRelToObject(delta, effect: _childrenEffect);
    lPos.applyDeltaRelToObject(delta, effect: (newLPos) => engineNode.lPos = recToVec3(newLPos));
    lRot.applyDeltaRelToObject(delta, effect: (newLRot) => engineNode.lRot = recToQuat(newLRot));
    lScale.applyDeltaRelToObject(delta, effect: (newLScale) => engineNode.lScale = recToVec3(newLScale));
  }

  void _childrenEffect(List<UUID> newChildren) {
    for (final child in children.get()) {
      if (newChildren.contains(child)) continue;
      engineNode.removeChild(StateTracker.getObject<Node>(child)!.engineNode);
    }
    for (final child in newChildren) {
      if (children.get().contains(child)) continue;
      engineNode.addChild(StateTracker.getObject<Node>(child)!.engineNode);
    }
  }
}

// void test() {
//   Node node = Node.create();
//   node.modifyLocal((builder) {
//     node.parent.set(builder, 'test');
//   });
// }
