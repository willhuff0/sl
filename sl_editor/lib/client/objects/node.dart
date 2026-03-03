import 'package:sl_editor/client/state_tracker.dart';
import 'package:sl_engine/node.dart' as engine;
import 'package:sl_shared/sl_shared.dart';
import 'package:vector_math/vector_math.dart';

final Map<engine.Node, Node> _engineNodeToTracker = {};

class Node extends StateTracked {
  final TrackedProperty<String> name = TrackedProperty(
    path: 'name',
    value: 'New Node',
    effect: (node, newName) => (node as Node).engineNode.name = newName,
  );
  final TrackedProperty<List<UUID>> children = TrackedProperty(
    path: 'children',
    value: [],
    effect: _childrenEffect,
  );
  final TrackedProperty<Vector3> lPos = TrackedProperty(
    path: 'lPos',
    value: Vector3.zero(),
    effect: (node, newLPos) => (node as Node).engineNode.lPos = newLPos,
    toJson: vec3ToJson,
    fromJson: vec3FromJson,
  );
  final TrackedProperty<Quaternion> lRot = TrackedProperty(
    path: 'lRot',
    value: Quaternion.identity(),
    effect: (node, newLRot) => (node as Node).engineNode.lRot = newLRot,
    toJson: quatToJson,
    fromJson: quatFromJson,
  );
  final TrackedProperty<Vector3> lScale = TrackedProperty(
    path: 'lScale',
    value: Vector3(1.0, 1.0, 1.0),
    effect: (node, newLScale) => (node as Node).engineNode.lScale = newLScale,
    toJson: vec3ToJson,
    fromJson: vec3FromJson,
  );

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
    name.applyDeltaRelToObject(this, delta);
    children.applyDeltaRelToObject(this, delta);
    lPos.applyDeltaRelToObject(this, delta);
    lRot.applyDeltaRelToObject(this, delta);
    lScale.applyDeltaRelToObject(this, delta);
  }

  static void _childrenEffect(StateTracked receiver, List<UUID> newChildren) {
    final node = (receiver as Node);
    for (final child in node.children.get()) {
      if (newChildren.contains(child)) continue;
      node.engineNode.removeChild(StateTracker.getObject<Node>(child)!.engineNode);
    }
    for (final child in newChildren) {
      if (node.children.get().contains(child)) continue;
      node.engineNode.addChild(StateTracker.getObject<Node>(child)!.engineNode);
    }
  }
}
