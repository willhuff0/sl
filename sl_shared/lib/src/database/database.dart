import 'package:sl_shared/sl_shared.dart';
import 'package:sqlite_crdt/sqlite_crdt.dart';

export 'asset.dart';

Future<SqliteCrdt> openDatabase(String path) async {
  return await SqliteCrdt.open(
    path,
    version: 1,
    onCreate: (db, version) async {
      await db.execute('PRAGMA foreign_keys = ON;');
      await db.execute('''
CREATE TABLE assets (
    uuid TEXT NOT NULL PRIMARY KEY,
    parent TEXT REFERENCES assets(uuid),
    name TEXT NOT NULL,
    type TEXT NOT NULL,
    properties TEXT,
    updated_at TEXT NOT NULL,
    blob_size INTEGER,
    blob_updated_at TEXT,
    blob_upload_progress INTEGER
);
''');
      await db.execute('CREATE INDEX idx_assets_parent ON assets(parent);');
    },
  );
}

const _getAssetByUUIDSql = 'SELECT * FROM assets WHERE uuid = ?1;';
Future<Asset?> getAssetByUUID(SqliteCrdt db, UUID uuid) async {
  final results = await db.query(_getAssetByUUIDSql, [uuid]);
  if (results.isEmpty) return null;
  return Asset.deserialize(results.first);
}

const _getAssetsInDirectorySql = '''
WITH RECURSIVE
  asset_tree AS (
      SELECT
          a.uuid,
          a.parent,
          a.name,
          a.type,
          a.properties,
          a.updated_at,
          a.blob_size,
          a.blob_updated_at,
          a.blob_upload_progress,
          0 AS depth
      FROM assets a
      WHERE a.parent = ?1 OR (a.parent IS NULL AND ?1 IS NULL)

      UNION ALL

      SELECT
          sa.uuid,
          sa.parent,
          sa.name,
          sa.type,
          sa.properties,
          sa.updated_at,
          sa.blob_size,
          sa.blob_updated_at,
          sa..blob_upload_progress,
          at.depth + 1
      FROM assets sa
      JOIN asset_tree at
          ON sa.parent = at.uuid
      WHERE at.type <> 0 -- type != directory
  )
  SELECT
      uuid,
      parent,
      name,
      type,
      properties,
      updated_at,
      blob_size,
      blob_updated_at,
      blob_upload_progress,
      depth
  FROM asset_tree
  ORDER BY depth, parent, name;
''';
Stream<(Map<UUID, Asset> assets, List<FoldedAsset> roots)> watchAssetsInDirectory(SqliteCrdt db, UUID? directory) {
  return db
      .watch(
        _getAssetsInDirectorySql,
        () => [directory],
      )
      .map((rows) {
        final idToAsset = <UUID, Asset>{};
        final idToFoldedAsset = <UUID, FoldedAsset>{};
        final idToDepth = <UUID, int>{};
        for (final row in rows) {
          final asset = Asset.deserialize(row);
          idToAsset[asset.uuid] = asset;
          idToFoldedAsset[asset.uuid] = FoldedAsset(
            uuid: asset.uuid,
            subAssets: [],
          );
          idToDepth[asset.uuid] = row['depth'] as int;
        }

        final roots = <FoldedAsset>[];
        for (final asset in idToAsset.values) {
          final current = idToFoldedAsset[asset.uuid]!;
          final depth = idToDepth[asset.uuid]!;
          if (depth == 0) {
            roots.add(current);
          } else {
            final parent = idToFoldedAsset[asset.parent]!;
            parent.subAssets.add(current);
          }
        }

        return (idToAsset, roots);
      });
}
