import 'package:sl_server/server.dart';
import 'package:sl_server/state_tracker.dart';
import 'package:sl_shared/sl_shared.dart';

class Scene {
  final UUID sceneId;
  final Map<int, ClientSceneState> clients = {};
  var hasAnyClientStateChanged = false;

  Scene(this.sceneId);
}

class SceneSystem {
  final Server server;
  late final StateTracker stateTracker;

  final Map<UUID, Scene> _scenes = {};

  SceneSystem(this.server) {
    stateTracker = StateTracker(
      server,
      StateTrackerSystem.scene,
      getInterestedClients: _getInterestedClients,
    );
  }

  void removeClient(Client client) {
    _removeClientFromScene(client);
  }

  bool handleMessage(Client client, Message message) {
    switch (message) {
      case CtsSetSceneState setSceneState:
        _setClientSceneState(client, setSceneState.sceneId, setSceneState.state);
        break;
      default:
        return false;
    }
    return true;
  }

  void tick() {
    for (final scope in _scenes.values) {
      if (scope.hasAnyClientStateChanged) {
        _broadcastClientSceneStates(scope);
        scope.hasAnyClientStateChanged = false;
      }
    }
  }

  Set<Client> _getInterestedClients(UUID uuid) {
    //final object = stateTracker.getObjectInMemory(uuid);
    // TOOD
    return {};
  }

  void _setClientSceneState(Client client, UUID? sceneId, ClientSceneState? newState) {
    if (sceneId == null || newState == null) {
      _removeClientFromScene(client);
      return;
    }
    if (sceneId != client.sceneId) {
      _removeClientFromScene(client);
    }

    var scope = _scenes[sceneId] ?? (_scenes[sceneId] = Scene(sceneId));
    scope.clients[client.clientId] = newState;
    scope.hasAnyClientStateChanged = true;

    client.state.sceneId = sceneId;
  }

  void _removeClientFromScene(Client client) {
    if (client.sceneId == null) return;

    final scope = _scenes[client.sceneId]!;
    scope.clients.remove(client.clientId);

    if (scope.clients.isEmpty) _scenes.remove(client.sceneId);
    client.state.sceneId = null;
  }

  void _broadcastClientSceneStates(Scene scene) {
    server.broadcast(
      StcSetClientSceneStates(
        sceneId: scene.sceneId,
        states: scene.clients,
      ),
      only: scene.clients.keys.map((clientId) => server.getClients()[clientId]!),
    );
  }
}
