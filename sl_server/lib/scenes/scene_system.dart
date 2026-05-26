import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:sl_server/client.dart';
import 'package:sl_server/scenes/node.dart';
import 'package:sl_server/server.dart';
import 'package:sl_server/state_tracker.dart';
import 'package:sl_shared/sl_shared.dart';
import 'package:uuid/uuid.dart';

const _autoSaveInterval = Duration(seconds: 30);

class Scene {
  final String path;
  final UUID sceneId;
  final UUID root;
  late final StateTracker stateTracker;

  final Map<Client, ClientSceneState> clients = {};
  var hasAnyClientStateChanged = false;

  late final Timer _autoSaveTimer;

  Scene({
    required Server server,
    required this.path,
    required this.sceneId,
    required this.root,
  }) {
    stateTracker = StateTracker(
      server,
      sceneId,
      getInterestedClients: () => clients.keys.toSet(),
    );

    _autoSaveTimer = Timer.periodic(_autoSaveInterval, (_) => save());
  }

  static Future<Scene?> loadFromFile({
    required Server server,
    required String path,
    required UUID sceneId,
  }) async {
    final file = File(path);
    if (!await file.exists()) return null;

    final content = await file.readAsString();
    final json = jsonDecode(content);

    final rootUuid = json['root'];
    final scene = Scene(
      path: path,
      server: server,
      sceneId: sceneId,
      root: rootUuid,
    );
    scene.stateTracker.fromJson(json);
    return scene;
  }

  Future<void> save() async {
    final file = File(path);
    await file.create(recursive: true);

    final json = stateTracker.toJson();
    json['root'] = root;

    final contents = jsonEncode(json);

    await file.writeAsString(contents, flush: true);

    print('Saved: $sceneId');
  }

  Future<void> dispose() async {
    await save();
    _autoSaveTimer.cancel();
  }
}

class SceneSystem {
  final Server server;

  final Map<UUID, Scene> _scenes = {};

  SceneSystem(this.server);

  Future<Scene?> _getOrCreateScene(UUID sceneId) async {
    if (!Uuid.isValidUUID(fromString: sceneId)) return null;

    final path = server.pathProvider.getSceneSavePath(sceneId);

    final loadedScene = await Scene.loadFromFile(
      server: server,
      sceneId: sceneId,
      path: path,
    );
    if (loadedScene != null) return loadedScene;

    final rootUuid = Uuid().v4();
    final newScene = Scene(
      path: path,
      server: server,
      sceneId: sceneId,
      root: rootUuid,
    );
    newScene.stateTracker.addObject(
      Node(newScene.stateTracker, rootUuid)..name.value = 'Root',
    );
    return newScene;
  }

  Future<void> dispose() async {
    for (final scene in _scenes.values) {
      await scene.dispose();
    }
  }

  Future<void> removeClient(Client client) async {
    await _removeClientFromScene(client);
  }

  Future<bool> handleMessage(Client client, Message message) async {
    switch (message) {
      case CtsStateChanges stateChanges:
        var scene = _scenes[stateChanges.sceneId];
        if (scene == null) {
          final loaded = await _getOrCreateScene(stateChanges.sceneId);
          if (loaded == null) break;

          scene = _scenes[stateChanges.sceneId] = loaded;
          await _setClientSceneState(
            client,
            stateChanges.sceneId,
            ClientSceneState(viewPosition: null),
          );
        }

        await scene.stateTracker.handleClientChanges(client, stateChanges);
        break;
      case CtsSetSceneState setSceneState:
        await _setClientSceneState(client, setSceneState.sceneId, setSceneState.state);
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

  Future<void> _setClientSceneState(Client client, UUID? sceneId, ClientSceneState? newState) async {
    if (sceneId == null || newState == null) {
      await _removeClientFromScene(client);
      return;
    }
    var changedScenes = false;
    if (sceneId != client.sceneId) {
      await _removeClientFromScene(client);
      changedScenes = true;
    }

    var scene = _scenes[sceneId];
    if (scene == null) {
      final loaded = await _getOrCreateScene(sceneId);
      if (loaded == null) return;

      scene = _scenes[sceneId] = loaded;
    }

    scene.clients[client] = newState;
    scene.hasAnyClientStateChanged = true;

    client.state.sceneId = sceneId;

    if (changedScenes) {
      scene.stateTracker.sendAllToClient(client, scene.root);
    }
  }

  Future<void> _removeClientFromScene(Client client) async {
    if (client.sceneId == null) return;

    final scene = _scenes[client.sceneId]!;
    scene.clients.remove(client);

    if (scene.clients.isEmpty) {
      _scenes.remove(client.sceneId);
      await scene.dispose();
    } else {
      scene.hasAnyClientStateChanged = true;
    }
    client.state.sceneId = null;
  }

  void _broadcastClientSceneStates(Scene scene) {
    server.sendToEach((client) {
      if (!scene.clients.containsKey(client)) return null;
      final states = Map.fromEntries(
        scene.clients.entries
            .where((entry) => entry.key != client)
            .map((entry) => MapEntry(entry.key.clientId, entry.value)),
      );
      if (states.isEmpty) return null;
      return StcSetClientSceneStates(
        sceneId: scene.sceneId,
        states: states,
      );
    });
  }
}
