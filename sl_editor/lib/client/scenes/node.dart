import 'dart:collection';

import 'package:sl_editor/client/bi_delta.dart';
import 'package:sl_editor/client/client.dart';
import 'package:sl_editor/client/state_tracker.dart';
import 'package:sl_editor/client/scenes/scene_system.dart';
import 'package:sl_editor/client/tracked_property.dart';
import 'package:sl_engine/node.dart' as engine;
import 'package:sl_engine/editor/selector.dart';
import 'package:sl_shared/sl_shared.dart';
import 'package:vector_math/vector_math.dart';

class Node extends SceneStateTracked {
  final TrackedProperty<String> name = TrackedProperty(
    path: 'name',
    value: 'New Node',
    effect: (node, newName) {
      (node as Node).engineNode.name = newName;
      Client.get().sceneSystem.onNodeAddedOrRemovedController.add(null);
    },
  );
  final TrackedProperty<ParentAndOrder?> parent = TrackedProperty(
    path: 'parent',
    value: null,
    effect: _parentEffect,
    fromJson: (v) => v == null ? null : ParentAndOrder.fromJson(v),
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
  final TrackedProperty<UUID?> asset = TrackedProperty(
    path: 'asset',
    value: null,
    effect: _assetEffect,
  );
  engine.Node? assetNode;

  final engine.Node engineNode;

  static ObjectClass get objectClass => 'node';

  static Node create(StateTracker<SceneStateTracked> tracker, UUID parent, String name) {
    final parentNode = tracker.getObject(parent) as Node;

    Fraction order;
    if (parentNode.children.isEmpty) {
      order = Fraction.zero;
    } else {
      order = parentNode.children.lastKey()! + Fraction.one;
    }

    final node = Node(tracker, generateUuid());
    node.parent.set(node, BiDeltaBuilder(), ParentAndOrder(uuid: parent, order: order));
    node.name.set(node, BiDeltaBuilder(), name);
    node.createThis(objectClass);
    return node;
  }

  Node(super.tracker, super.uuid)
    : engineNode = engine.Node(name: 'New Node'),
      super(
        doesExistEffect: (node, newDoesExist) {
          if (!newDoesExist) {
            Client.get().sceneSystem.onNodeAddedOrRemovedController.add(null);
            (node as Node).engineNode.parent!.removeChild(node.engineNode);
            node.engineNode.exitScene();
          }
        },
      );

  void delete() {
    // Make a copy of the values before iterating, since deleting children removes them from the map.
    final currentChildren = children.values.toList();
    for (final child in currentChildren) {
      child.delete();
    }

    modifyLocal((builder) {
      doesExist.set(this, builder, false);
    });
  }

  /// Moves this node to a new parent, and optionally positions it between `before` and `after`.
  void moveTo(Node newParent, {Node? before, Node? after}) {
    Fraction newOrder;

    if (before == null && after == null) {
      // No specific siblings requested
      if (newParent.children.isEmpty) {
        newOrder = Fraction.zero; // First node
      } else {
        // Just append to the very end
        newOrder = newParent.children.lastKey()! + Fraction.one;
      }
    } else if (before != null && after == null) {
      // Place after the chosen 'before' node (at the new end)
      newOrder = before.parent.get()!.order + Fraction.one;
    } else if (before == null && after != null) {
      // Place before the chosen 'after' node (at the new beginning)
      newOrder = after.parent.get()!.order - Fraction.one;
    } else {
      // Place exactly between the two sibling nodes
      newOrder = Fraction.midpoint(before!.parent.get()!.order, after!.parent.get()!.order);
    }

    final realWPos = engineNode.wPos.clone();
    final realWRot = engineNode.wRot.clone();
    final realWScale = engineNode.wScale.clone();

    final previousParent = engineNode.parent;
    newParent.engineNode.addChild(engineNode);

    engineNode.wPos = realWPos;
    engineNode.wRot = realWRot;
    engineNode.wScale = realWScale;

    final newLPos = engineNode.lPos;
    final newLRot = engineNode.lRot;
    final newLScale = engineNode.lScale;

    if (previousParent != null) {
      previousParent.addChild(engineNode);
    } else {
      newParent.engineNode.removeChild(engineNode);
    }

    modifyLocal((builder) {
      parent.set(this, builder, ParentAndOrder(uuid: newParent.uuid, order: newOrder));
      lPos.set(this, builder, newLPos);
      lRot.set(this, builder, newLRot);
      lScale.set(this, builder, newLScale);
    });
  }

  @override
  void getDeltaFromNull(Delta builder) {
    name.getDeltaFromNullRelToObject(builder);
    parent.getDeltaFromNullRelToObject(builder);
    lPos.getDeltaFromNullRelToObject(builder);
    lRot.getDeltaFromNullRelToObject(builder);
    lScale.getDeltaFromNullRelToObject(builder);
    asset.getDeltaFromNullRelToObject(builder);
    super.getDeltaFromNull(builder);
  }

  @override
  void applyDelta(Delta delta) {
    name.applyDeltaRelToObject(this, delta);
    parent.applyDeltaRelToObject(this, delta);
    lPos.applyDeltaRelToObject(this, delta);
    lRot.applyDeltaRelToObject(this, delta);
    lScale.applyDeltaRelToObject(this, delta);
    asset.applyDeltaRelToObject(this, delta);
    super.applyDelta(delta);
  }

  static void _parentEffect(StateTracked receiver, ParentAndOrder? newParent) {
    final node = (receiver as Node);
    if (node.parent.get() != null) {
      final parentNode = receiver.tracker.getObject<Node>(node.parent.get()!.uuid)!;
      parentNode.children.remove(node.parent.get()!.order);
      parentNode.engineNode.removeChild(node.engineNode);
    }
    if (newParent != null) {
      final newParentNode = receiver.tracker.getObject<Node>(newParent.uuid)!;
      newParentNode.children[newParent.order] = node;
      newParentNode.engineNode.addChild(node.engineNode);
    } else {
      Client.get().sceneSystem.setRoot(node);
    }

    Client.get().sceneSystem.onNodeAddedOrRemovedController.add(null);
  }

  static void _assetEffect(StateTracked receiver, UUID? newAsset) async {
    final node = (receiver as Node);

    if (newAsset == null) {
      if (node.assetNode != null) {
        Selector.removeRealNode(node.assetNode!);
        node.engineNode.removeChild(node.assetNode!);
        node.assetNode!.exitScene();
        node.assetNode = null;
      }
      return;
    }
    final asset = await getAssetByUuid(Client.get().assetSystem.sharedDatabase, newAsset);
    if (asset == null) {
      if (node.assetNode != null) {
        Selector.removeRealNode(node.assetNode!);
        node.engineNode.removeChild(node.assetNode!);
        node.assetNode!.exitScene();
        node.assetNode = null;
      }
      return;
    }

    await Client.get().sceneSystem.addGltfToRealNode(asset, node);
  }
}
