import 'package:drift/drift.dart';
import 'package:sl_server/database/assets_dao.dart';
import 'package:sl_server/database/database.dart';
import 'package:sl_server/server.dart';
import 'package:sl_shared/sl_shared.dart';
import 'package:uuid/uuid.dart';

class Assets {
  final Server server;
  final Database db;

  final Map<Client, UUID?> _clientToSubscribedDirectories = {};
  final Map<UUID?, Set<Client>> _directoryToSubscribedClients = {};

  Assets({
    required this.server,
    required this.db,
  });

  void clientListenToDirectory(Client client, UUID? directory) {
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

  void registerRpcHandlers(Client client) {
    client.rpc.registerMethod('getAssetsInDirectory', (directory) async {
      return (null, await AssetsDao.getAssetEntriesInDirectory(db, directory));
    });
    client.rpc.registerMethod('addAssets', (dynamic createInfo) async {
      final uuid = Uuid().v4();
      await AssetsDao.createAsset(
        db,
        uuid: uuid,
        parent: createInfo['parent'],
        name: createInfo['name'],
        type: AssetType.values[createInfo['type']],
      );
      return (null, uuid);
    });
  }

  Future<List<AssetEntry>> getAssetEntriesInDirectory(Database db, UUID? directory) async {
    final rows = await db.getAssetsInDirectory(directory).get();

    final idToAsset = <String, AssetEntry>{};
    for (final row in rows) {
      idToAsset[row.uuid] = AssetEntry(
        uuid: row.uuid,
        name: row.name,
        type: row.type,
        subAssets: [],
        blobSize: row.blobSize,
      );
    }

    final roots = <AssetEntry>[];
    for (final row in rows) {
      final current = idToAsset[row.uuid]!;
      if (row.depth == 0) {
        roots.add(current);
      } else {
        final parent = idToAsset[row.parent]!;
        parent.subAssets.add(current);
      }
    }

    return roots;
  }

  Future<void> _addAssets(UUID? directory, List<AssetEntry> entries) async {
    if (entries.any((entry) => !entry.validate())) {
      // TODO: error
      return;
    }

    await db.batch((b) {
      final toVisit = List<(UUID?, AssetEntry)>.generate(entries.length, (i) => (null, entries[i]));
      while (toVisit.isNotEmpty) {
        final (parent, asset) = toVisit.removeLast();

        b.insert(
          db.assets,
          AssetsCompanion.insert(
            parent: Value(parent),
            uuid: asset.uuid,
            name: asset.name,
            type: asset.type,
            blobSize: 0,
          ),
        );

        for (final subAsset in asset.subAssets) {
          toVisit.add((asset.uuid, subAsset));
        }
      }
    });

    _notifyAssetsChanged(directory, entries, []);
  }

  void _notifyAssetsChanged(UUID? directory, List<AssetEntry> updated, List<UUID> removed) {
    final clients = _directoryToSubscribedClients[directory] ?? {};
    server.broadcast(
      StcAssetDirectoryListenUpdate(
        directory: directory,
        updated: updated,
        removed: removed,
      ),
      only: clients,
    );
  }
}
