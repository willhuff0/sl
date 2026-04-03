import 'package:drift/drift.dart';
import 'package:sl_server/database/database.dart';
import 'package:sl_shared/sl_shared.dart';

class AssetsDao {
  static Future<List<AssetEntry>> getAssetEntriesInDirectory(Database db, UUID? directory) async {
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

  static Future<void> createAsset(
    Database db, {
    required UUID uuid,
    required UUID? parent,
    required String name,
    required AssetType type,
  }) async {
    await db.assets.insertOne(
      AssetsCompanion.insert(
        uuid: uuid,
        name: name,
        type: type,
        blobSize: 0,
      ),
    );
  }
}
