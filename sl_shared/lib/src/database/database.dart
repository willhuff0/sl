import 'package:sl_shared/sl_shared.dart';
import 'package:sqlite_crdt/sqlite_crdt.dart';

export 'asset.dart';

const _version = 1;
Future<void> _onCreate(CrdtTableExecutor db, int version) async {
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
    blob_version INTEGER,
    thumb_mime TEXT
);
''');
  await db.execute('CREATE INDEX idx_assets_parent ON assets(parent);');
}

Future<SqliteCrdt> openDatabase(String path) async {
  return await SqliteCrdt.open(
    path,
    version: _version,
    onCreate: _onCreate,
  );
}

Future<SqliteCrdt> openDatabaseInMemory() async {
  return await SqliteCrdt.openInMemory(
    version: _version,
    onCreate: _onCreate,
  );
}

const _getAllAssetUuidsSql = 'SELECT uuid FROM assets WHERE is_deleted = 0;';
Future<Set<UUID>> getAllAssetUuids(SqliteCrdt db) async {
  final results = await db.query(_getAllAssetUuidsSql);
  return results.map((row) => row['uuid'] as String).toSet();
}

Future<void> deleteAssets(SqliteCrdt db, List<UUID> toDelete) async {
  await db.execute('''
WITH RECURSIVE 
roots(uuid) AS (
  VALUES ${List.generate(toDelete.length, (i) => '(?${i + 1})').join(',')}
),
subtree(uuid) AS (
  SELECT uuid
  FROM roots

  UNION ALL

  SELECT a.uuid
  FROM assets AS a
  JOIN subtree AS s ON a.parent = s.uuid
)
DELETE FROM assets
WHERE uuid IN (SELECT uuid FROM subtree) AND is_deleted = 0;
''', toDelete);
}
