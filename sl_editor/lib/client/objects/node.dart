import 'dart:collection';

import 'package:sl_editor/client/state_tracker.dart';
import 'package:sl_editor/client/tracked_property.dart';
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
  final TrackedProperty<ParentAndOrder?> parent = TrackedProperty(
    path: 'parent',
    value: null,
    effect: _parentEffect,
  );
  final SplayTreeMap<Fraction, Node> children = SplayTreeMap();
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

  Node(super.uuid)
    : engineNode = engine.Node(name: 'New Node'),
      super(
        doesExistEffect: (node, newDoesExist) {
          if (!newDoesExist) {
            // TODO: delete node
            (node as Node).engineNode.exitScene();
          }
        },
      ) {
    _engineNodeToTracker[engineNode] = this;

    // TODO: temporary
    // root.addChild(engineNode);
    // engineNode.addComponent(MeshComponent(mesh: cubeMesh));
    // engineNode.enterScene();
  }

  @override
  void getDeltaFromNull(Delta builder) {
    name.getDeltaFromNullRelToObject(builder);
    parent.getDeltaFromNullRelToObject(builder);
    lPos.getDeltaFromNullRelToObject(builder);
    lRot.getDeltaFromNullRelToObject(builder);
    lScale.getDeltaFromNullRelToObject(builder);
    super.getDeltaFromNull(builder);
  }

  @override
  void applyDelta(Delta delta) {
    name.applyDeltaRelToObject(this, delta);
    parent.applyDeltaRelToObject(this, delta);
    lPos.applyDeltaRelToObject(this, delta);
    lRot.applyDeltaRelToObject(this, delta);
    lScale.applyDeltaRelToObject(this, delta);
    super.applyDelta(delta);
  }

  static void _parentEffect(StateTracked receiver, ParentAndOrder? newParent) {
    final node = (receiver as Node);
    if (node.parent.get() != null) {
      final parentNode = StateTracker.getObject<Node>(node.parent.get()!.uuid)!;
      parentNode.children.remove(node.parent.get()!.order);
      parentNode.engineNode.removeChild(node.engineNode);
    } else {
      // TODO: temporary
      // root.removeChild(node.engineNode);
    }
    if (newParent != null) {
      final newParentNode = StateTracker.getObject<Node>(newParent.uuid)!;
      newParentNode.children[newParent.order] = node;
      newParentNode.engineNode.addChild(node.engineNode);
    } else {
      // TODO: temporary
      // root.addChild(node.engineNode);
    }
  }
}
