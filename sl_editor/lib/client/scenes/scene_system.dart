import 'dart:async';
import 'dart:ui';

import 'package:sl_editor/client/client.dart';
import 'package:sl_editor/client/scenes/node.dart';
import 'package:sl_editor/client/state_tracker.dart';
import 'package:sl_editor/client/view_manager.dart';
import 'package:sl_editor/importers/gltf.dart';
import 'package:sl_engine/editor/selector.dart';
import 'package:sl_engine/editor/sl_editor.dart';
import 'package:sl_engine/gl/gltf.dart';
import 'package:sl_shared/sl_shared.dart';
import 'package:vector_math/vector_math.dart';
import 'package:sl_engine/node.dart' as engine;

Vector4 _intToVec4Color(int value) {
  final color = Color(value);
  return Vector4(color.r, color.g, color.b, color.a);
}

class Scene {
  final UUID sceneId;
  final String name;

  ClientSceneState selfState;
  Map<int, ClientSceneState> states = {};

  Scene({
    required this.sceneId,
    required this.name,
    required this.selfState,
  });
}

abstract class SceneStateTracked extends StateTracked {
  SceneStateTracked(super.tracker, super.uuid, {super.doesExistEffect});
}

class SceneSystem {
  final Client client;

  SceneSystem(this.client);

  Scene? _scene;
  StateTracker<SceneStateTracked>? stateTracker;
  final _engineNodeToTracked = <engine.Node, Node>{};

  final _onRootChangedController = StreamController<Node?>.broadcast();
  late final onRootChanged = _onRootChangedController.stream;

  final onNodeAddedOrRemovedController = StreamController.broadcast();
  late final onNodeAddedOrRemoved = onNodeAddedOrRemovedController.stream;

  StreamSubscription? _onSelectionTransformedSubscription;

  final _gltfCache = <String, FutureOr<GLTF?>>{};

  void loadScene(UUID newSceneId, String name) {
    if (newSceneId == _scene?.sceneId) {
      Client.get().send(
        CtsSetSceneState(
          sceneId: null,
          state: null,
        ),
      );
    }

    final newState = ClientSceneState(
      viewPosition: null,
    );

    _scene = Scene(
      sceneId: newSceneId,
      name: name,
      selfState: newState,
    );

    stateTracker?.submitLocalChangesIfPresent();
    stateTracker = StateTracker(
      sceneId: newSceneId,
      constructors: {
        Node.objectClass: Node.new,
      },
      onObjectAdded: _registerObject,
    );

    _engineNodeToTracked.clear();

    setRoot(null);

    _gltfCache.clear();

    Client.get().send(
      CtsSetSceneState(
        sceneId: newSceneId,
        state: newState,
      ),
    );

    _onSelectionTransformedSubscription?.cancel();
    _onSelectionTransformedSubscription = Selector.onSelectionTransformed.listen(_onSelectionTransformed);
  }

  void _onSelectionTransformed(Set<engine.Node> nodes) {
    for (final node in nodes) {
      final trackedNode = getTrackedFromEngineNode(node);
      trackedNode.modifyLocal((builder) {
        if (trackedNode.lPos.get() != node.lPos) trackedNode.lPos.set(trackedNode, builder, node.lPos);
        if (trackedNode.lRot.get() != node.lRot) trackedNode.lRot.set(trackedNode, builder, node.lRot);
        if (trackedNode.lScale.get() != node.lScale) trackedNode.lScale.set(trackedNode, builder, node.lScale);
      });
    }
  }

  void setRoot(Node? node) {
    SLEditor.changeScene(node?.engineNode);

    _onRootChangedController.add(node);
    if (node != null && _scene != null) {
      if (node.name.get() != _scene!.name) {
        node.modifyLocal((builder) {
          node.name.set(node, builder, _scene!.name);
        });
      }
    }
  }

  Future<void> createNewGltfAssetNode(Asset asset, Node parent) async {
    final node = Node.create(Client.get().sceneSystem.stateTracker!, parent.uuid, asset.name);

    node.modifyLocal((builder) {
      node.asset.set(node, builder, asset.uuid);
    });
  }

  Future<void> addGltfToRealNode(Asset asset, Node realNode) async {
    if (!_gltfCache.containsKey(asset.uuid)) {
      _gltfCache[asset.uuid] = () async {
        final extension = asset.properties?['extension'] ?? '.glb';
        final gltfPath = '${asset.uuid}$extension';

        final redirects = (asset.properties?['redirects'] as Map?)?.cast<String, UUID>() ?? {};
        redirects[gltfPath] = asset.uuid;
        final resourceLoader = GLTFAssetResourceLoader(redirects: redirects);
        return _gltfCache[asset.uuid] = await GLTF.load(gltfPath, resourceLoader: resourceLoader);
      }();
    }
    // Logger.log('adding gltf \'${asset.uuid}\' to ${realNode.name.get()}');
    final gltf = await _gltfCache[asset.uuid];
    if (gltf == null) return;

    final gltfEngineNode = gltf.root.clone();
    gltfEngineNode.setRealNode(realNode.engineNode);
    realNode.engineNode.addChild(gltfEngineNode);
    gltfEngineNode.enterScene();

    if (realNode.assetNode != null) {
      realNode.engineNode.removeChild(realNode.assetNode!);
      realNode.assetNode!.exitScene();
    }
    realNode.assetNode = gltfEngineNode;
  }

  Node getTrackedFromEngineNode(engine.Node node) {
    return _engineNodeToTracked[node]!;
  }

  void _registerObject(SceneStateTracked object) {
    switch (object) {
      case Node node:
        _engineNodeToTracked[node.engineNode] = node;
        node.engineNode.enterScene();
        onNodeAddedOrRemovedController.add(node);
        break;
    }
  }

  Future<bool> handleMessage(Message message) async {
    switch (message) {
      case StcLocalChangeDecisions localChangeDecisions:
        if (stateTracker == null || localChangeDecisions.sceneId != stateTracker!.sceneId) break;
        stateTracker!.handleChangeDecisions(localChangeDecisions);
        break;
      case StcRemoteChanges remoteChanges:
        if (stateTracker == null || remoteChanges.sceneId != stateTracker!.sceneId) break;
        stateTracker!.handleRemoteChanges(remoteChanges);
        break;
      case StcSetClientSceneStates setClientSceneStates:
        _setClientSceneStates(setClientSceneStates.sceneId, setClientSceneStates.states);
        break;
      default:
        return false;
    }
    return true;
  }

  void tick() {
    if (_scene != null && ViewManager.hasViewChangedAndUpdate()) {
      _scene!.selfState.viewPosition = ViewManager.getViewPosition();
      _sendSceneState();
    }
    stateTracker?.submitLocalChangesIfPresent();
  }

  void _setClientSceneStates(UUID newSceneId, Map<ClientId, ClientSceneState> newStates) {
    if (_scene?.sceneId != newSceneId) {
      _sendSceneState();
      return;
    }
    _scene!.states = newStates;
    if (stateTracker != null) {
      ViewManager.setRemoteViewPositions(
        stateTracker!,
        Map.fromEntries(
          _scene!.states.entries
              .where((entry) => entry.value.viewPosition != null)
              .map(
                (entry) => MapEntry(entry.key, (
                  _intToVec4Color(client.getClientStates()[entry.key]!.color),
                  entry.value.viewPosition!,
                )),
              ),
        ),
      );
    }
  }

  void _sendSceneState() {
    Client.get().send(
      CtsSetSceneState(
        sceneId: _scene?.sceneId,
        state: _scene?.selfState,
      ),
    );
  }
}
