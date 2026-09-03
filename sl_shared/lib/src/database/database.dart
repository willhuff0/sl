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

const _getAllAssetUuids = 'SELECT uuid FROM assets WHERE is_deleted = 0;';
Future<Set<UUID>> getAllAssetUuids(SqliteCrdt db) async {
  final results = await db.query(_getAllAssetUuids);
  return results.map((row) => row['uuid'] as String).toSet();
}
