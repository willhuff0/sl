import 'dart:ui';

import 'package:sl_editor/client/client.dart';
import 'package:sl_editor/client/objects/node.dart';
import 'package:sl_editor/client/state_tracker.dart';
import 'package:sl_editor/client/view_manager.dart';
import 'package:sl_shared/sl_shared.dart';
import 'package:vector_math/vector_math.dart';
import 'package:sl_engine/node.dart' as engine;

Vector4 _intToVec4Color(int value) {
  final color = Color(value);
  return Vector4(color.r, color.g, color.b, color.a);
}

class Scene {
  final UUID sceneId;
  Map<int, ClientSceneState> states = {};

  Scene(this.sceneId);
}

abstract class SceneStateTracked extends StateTracked {
  SceneStateTracked(super.tracker, super.uuid, {super.doesExistEffect});
}

class SceneSystem {
  final Client client;
  late final StateTracker<SceneStateTracked> stateTracker;

  final _engineNodeToTracked = <engine.Node, Node>{};

  SceneSystem(this.client) {
    stateTracker = StateTracker(
      .scene,
      constructors: {
        Node.objectClass: Node.new,
      },
      onObjectAdded: _registerObject,
    );
  }

  Scene? _scene;

  void loadScene(UUID newScene) {
    final newState = ClientSceneState(
      viewPosition: null,
    );

    stateTracker.changeScope(newScene);
    _scene = Scene(newScene)..states[Client.get().getClientId()] = newState;
    Client.get().send(
      CtsSetSceneState(
        sceneId: newScene,
        state: newState,
      ),
    );
  }

  void _registerObject(SceneStateTracked object) {
    switch (object) {
      case Node node:
        _engineNodeToTracked[node.engineNode] = node;
        break;
    }
  }

  Future<bool> handleMessage(Message message) async {
    switch (message) {
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
      _scene!.states[client.getClientId()]!.viewPosition = ViewManager.getViewPosition();
      _sendSceneState();
    }
    stateTracker.tick();
  }

  void _setClientSceneStates(UUID newSceneId, Map<ClientId, ClientSceneState> newStates) {
    if (_scene?.sceneId != newSceneId) {
      _sendSceneState();
      return;
    }
    _scene!.states = newStates;
    ViewManager.setRemoteViewPositions(
      stateTracker,
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

  void _sendSceneState() {
    Client.get().send(
      CtsSetSceneState(
        sceneId: _scene?.sceneId,
        state: _scene?.states[client.getClientId()],
      ),
    );
  }
}
