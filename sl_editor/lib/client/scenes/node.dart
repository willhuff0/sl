import 'dart:collection';

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
    NodeSchema.name,
    reconcile: (node, from, to) {
      (node as Node).engineNode.name = to;
      Client.get().sceneSystem.onNodeAddedOrRemovedController.add(null);
    },
  );
  final TrackedProperty<ParentAndOrder?> parent = TrackedProperty(
    NodeSchema.parent,
    reconcile: (node, from, to) {
      (node as Node)._detachFromParent(from);
      node._attachToParent(to);
      Client.get().sceneSystem.onNodeAddedOrRemovedController.add(null);
    },
  );
  final SplayTreeMap<Fraction, Node> children = SplayTreeMap();
  final TrackedProperty<Vector3> lPos = TrackedProperty(
    NodeSchema.lPos,
    reconcile: (node, from, to) => (node as Node).engineNode.lPos = to,
  );
  final TrackedProperty<Quaternion> lRot = TrackedProperty(
    NodeSchema.lRot,
    reconcile: (node, from, to) => (node as Node).engineNode.lRot = to,
  );
  final TrackedProperty<Vector3> lScale = TrackedProperty(
    NodeSchema.lScale,
    reconcile: (node, from, to) => (node as Node).engineNode.lScale = to,
  );
  final TrackedProperty<UUID?> asset = TrackedProperty(
    NodeSchema.asset,
    reconcile: (node, from, to) => (node as Node)._applyAsset(to),
  );
  engine.Node? assetNode;

  /// Guards async asset loads: a stale load whose token no longer matches is discarded.
  int _assetToken = 0;

  final engine.Node engineNode;

  static ObjectClass get objectClass => NodeSchema.objectClass;

  static Node create(StateTracker<SceneStateTracked> tracker, UUID parent, String name) {
    final parentNode = tracker.getObject(parent) as Node;

    Fraction order;
    if (parentNode.children.isEmpty) {
      order = Fraction.zero;
    } else {
      order = parentNode.children.lastKey()! + Fraction.one;
    }

    final node = Node(tracker, generateUuid());
    node.createThis(objectClass, (builder) {
      node.name.stage(builder, name);
      node.parent.stage(builder, ParentAndOrder(uuid: parent, order: order));
    });
    return node;
  }

  Node(super.tracker, super.uuid) : engineNode = engine.Node(name: 'New Node');

  @override
  List<TrackedProperty> get properties => [name, parent, lPos, lRot, lScale, asset];

  // --- lifecycle -------------------------------------------------------------------------------

  @override
  void realizeCreate() {
    engineNode.name = name.value;
    engineNode.lPos = lPos.value;
    engineNode.lRot = lRot.value;
    engineNode.lScale = lScale.value;

    // Attach to the parent before entering the scene so world transforms and component enable state
    // are computed against the correct ancestry.
    _attachToParent(parent.value);

    Client.get().sceneSystem.registerEngineNode(this);
    engineNode.enterScene();
    Client.get().sceneSystem.onNodeAddedOrRemovedController.add(null);

    if (asset.value != null) _applyAsset(asset.value);
  }

  @override
  void realizeDestroy() {
    Client.get().sceneSystem.onNodeAddedOrRemovedController.add(null);
    _clearAssetNode();
    _detachFromParent(parent.value);
    engineNode.exitScene();
    Client.get().sceneSystem.unregisterEngineNode(this);
  }

  // --- structural helpers (shared by realize* and the parent reconcile) ------------------------

  void _attachToParent(ParentAndOrder? to) {
    if (to != null) {
      final toParent = tracker.getObject<Node>(to.uuid);
      if (toParent != null) {
        toParent.children[to.order] = this;
        toParent.engineNode.addChild(engineNode);
      }
    } else {
      Client.get().sceneSystem.setRoot(this);
    }
  }

  void _detachFromParent(ParentAndOrder? from) {
    if (from == null) return;
    final fromParent = tracker.getObject<Node>(from.uuid);
    fromParent?.children.remove(from.order);
    fromParent?.engineNode.removeChild(engineNode);
  }

  void _clearAssetNode() {
    if (assetNode != null) {
      Selector.removeRealNode(assetNode!);
      engineNode.removeChild(assetNode!);
      assetNode!.exitScene();
      assetNode = null;
    }
  }

  void _applyAsset(UUID? newAsset) async {
    final token = ++_assetToken;

    if (newAsset == null) {
      _clearAssetNode();
      return;
    }

    final asset = await Client.get().assetSystem.sharedDatabase.getAsset(newAsset);
    if (token != _assetToken) return; // superseded by a newer asset value
    if (asset == null) {
      _clearAssetNode();
      return;
    }

    await Client.get().sceneSystem.addGltfToRealNode(asset, this);
  }

  // --- editor operations -----------------------------------------------------------------------

  void delete() {
    // Make a copy of the values before iterating, since deleting children removes them from the map.
    final currentChildren = children.values.toList();
    for (final child in currentChildren) {
      child.delete();
    }

    modifyLocal((builder) {
      doesExist.stage(builder, false);
    });
  }

  /// Moves this node to a new parent, and optionally positions it between `before` and `after`.
  void moveTo(Node newParent, {Node? before, Node? after}) {
    // Cannot reparent root
    if (parent.value == null) return;

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
      newOrder = before.parent.value!.order + Fraction.one;
    } else if (before == null && after != null) {
      // Place before the chosen 'after' node (at the new beginning)
      newOrder = after.parent.value!.order - Fraction.one;
    } else {
      // Place exactly between the two sibling nodes
      newOrder = Fraction.midpoint(before!.parent.value!.order, after!.parent.value!.order);
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
      parent.stage(builder, ParentAndOrder(uuid: newParent.uuid, order: newOrder));
      lPos.stage(builder, newLPos);
      lRot.stage(builder, newLRot);
      lScale.stage(builder, newLScale);
    });
  }
}
