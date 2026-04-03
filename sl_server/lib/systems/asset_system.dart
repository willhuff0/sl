import 'package:sl_server/database/database.dart';
import 'package:sl_server/server.dart';
import 'package:sl_server/state_tracker.dart';
import 'package:sl_shared/sl_shared.dart';

class AssetSystem {
  final Server server;
  final Database database;
  late final StateTracker stateTracker;

  final Map<Client, UUID?> _clientToSubscribedDirectories = {};
  final Map<UUID?, Set<Client>> _directoryToSubscribedClients = {};

  AssetSystem(this.server, this.database) {
    stateTracker = StateTracker(server, StateTrackerSystem.asset);
  }

  void removeClient(Client client) {
    // _removeClientFromScene(client);
  }

  bool handleMessage(Client client, Message message) {
    switch (message) {
      case CtsListenToAssetDirectory listenToAssetDirectory:
        // clientListenToDirectory(client, listenToAssetDirectory.directory);
        break;
      default:
        return false;
    }
    return true;
  }

  void tick() {}

  void _setClientListenDirectory(Client client, UUID? directory) {
    if (_clientToSubscribedDirectories.containsKey(client)) {
      if (directory != _clientToSubscribedDirectories[client]) {
        _removeClientListenDirectory(client);
      }
    }

    if (directory != _clientToSubscribedDirectories[client]) {}

    var current = _clientToSubscribedDirectories[client];
    if (current != null) {
      final subscribedClientsToCurrent = _directoryToSubscribedClients[current]!;
      subscribedClientsToCurrent.remove(client);
      if (subscribedClientsToCurrent.isEmpty) {
        _directoryToSubscribedClients.remove(current);
      }
    }

    _clientToSubscribedDirectories[client] = directory;
    var subscribedClients = _directoryToSubscribedClients[directory] ??= {};
    subscribedClients.add(client);
  }

  void _removeClientListenDirectory(Client client) {}
}
