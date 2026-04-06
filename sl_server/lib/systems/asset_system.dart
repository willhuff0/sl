import 'package:sl_server/database/database.dart';
import 'package:sl_server/objects/asset.dart';
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
    stateTracker = StateTracker(
      server,
      StateTrackerSystem.asset,
      getInterestedClients: _getInterestedClients,
      loadObjectFromDisk: _loadObjectFromDisk,
    );
  }

  void removeClient(Client client) {
    _removeClientListenDirectory(client);
  }

  bool handleMessage(Client client, Message message) {
    switch (message) {
      case CtsCreateAssets createAssets:
        // _createAssets(createAssets.createInfos);
        break;
      case CtsDeleteAssets deleteAssets:
        break;
      case CtsListenToAssetDirectory listenToAssetDirectory:
        _setClientListenDirectory(client, listenToAssetDirectory.directory);
        break;
      case PtpAssetBlob blob:
        break;
      default:
        return false;
    }
    return true;
  }

  void tick() {}

  Set<Client> _getInterestedClients(UUID uuid) {
    // TODO
    return {};
  }

  Future<StateTracked?> _loadObjectFromDisk(UUID uuid) async {
    final asset = await database.getAssetByUUID(uuid).getSingleOrNull();
    if (asset == null) return null;
    return TrackedAsset.fromDatabase(stateTracker, asset);
  }

  // void _createAssets(List<AssetCreateInfo> createInfos) {
  //   if (createInfos.any((createInfo) => !createInfo.validate()) return;
  //   for (final createInfo in createInfos) {}
  // }

  void _setClientListenDirectory(Client client, UUID? directory) {
    if (_clientToSubscribedDirectories.containsKey(client)) {
      if (directory != _clientToSubscribedDirectories[client]) {
        _removeClientListenDirectory(client);
      }
    }

    if (directory != _clientToSubscribedDirectories[client]) {}

    final current = _clientToSubscribedDirectories[client];
    if (current != null) {
      final subscribedClientsToCurrent = _directoryToSubscribedClients[current]!;
      subscribedClientsToCurrent.remove(client);
      if (subscribedClientsToCurrent.isEmpty) {
        _directoryToSubscribedClients.remove(current);
      }
    }

    _clientToSubscribedDirectories[client] = directory;
    final subscribedClients = _directoryToSubscribedClients[directory] ??= {};
    subscribedClients.add(client);

    // await _sendEntireDirectory(client, directory);
    _loadAndSendEntireDirectory(client, directory);
  }

  void _removeClientListenDirectory(Client client) {
    if (!_clientToSubscribedDirectories.containsKey(client)) return;

    final directory = _clientToSubscribedDirectories.remove(client);
    final subscribedClients = _directoryToSubscribedClients[directory]!;
    subscribedClients.remove(client);

    if (subscribedClients.isEmpty) _directoryToSubscribedClients.remove(directory);
  }

  Future<void> _loadAndSendEntireDirectory(Client client, UUID? directory) async {
    final rows = await database.getAssetsInDirectory(directory).get();
    stateTracker.preloadObjects(
      rows
          .where((row) => !stateTracker.isObjectLoaded(row.uuid))
          .map(
            (row) => TrackedAsset.fromDatabase(
              stateTracker,
              Asset(
                uuid: row.uuid,
                parent: row.parent,
                name: row.name,
                type: row.type,
                properties: row.properties,
                blobSize: row.blobSize,
              ),
            ),
          ),
    );
  }
}
