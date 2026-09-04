import 'dart:typed_data';

import 'package:sl_editor/client/assets/builtin_assets.dart';
import 'package:sl_editor/client/client.dart';
import 'package:sl_engine/utils/resource_loader.dart';
import 'package:sl_shared/sl_shared.dart';
import 'package:sqlite_crdt/sqlite_crdt.dart';
// ignore: implementation_imports
import 'package:sqlite_crdt/src/batch_executor.dart' show BatchExecutor;

class SharedDatabase {
  final SqliteCrdt _db;

  SharedDatabase(this._db);

  BuiltinAsset? _getBuiltinAsset(UUID uuid) {
    return builtinAssets[uuid];
  }

  bool isBuiltinAsset(UUID uuid) {
    return uuid.startsWith('&');
  }

  Future<(bool exists, Uint8List? bytes)> getBuiltinAssetBlob(UUID uuid) async {
    final asset = _getBuiltinAsset(uuid);
    if (asset == null) return (false, null);

    final path = asset.blobPath;
    if (path == null) return (true, null);

    final bytes = await BuiltInResourceLoader.get().loadBytes(path);
    return (true, bytes);
  }

  Future<bool> doesAssetExist(UUID uuid) async {
    if (isBuiltinAsset(uuid)) {
      return _getBuiltinAsset(uuid) != null;
    }

    final rows = await _db.query('SELECT 1 FROM assets WHERE uuid = ? AND is_deleted = 0', [uuid]);
    return rows.isNotEmpty;
  }

  Future<Asset?> getAsset(UUID uuid) async {
    if (isBuiltinAsset(uuid)) {
      return _getBuiltinAsset(uuid)?.mockDatabaseAsset;
    }

    final rows = await _db.query('SELECT * FROM assets WHERE uuid = ?1 AND is_deleted = 0;', [uuid]);
    if (rows.isEmpty) return null;
    return Asset.deserialize(rows.first);
  }

  static const _getAssetsInDirectorySql = '''
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
          a.blob_version,
          a.thumb_mime,
          0 AS depth
      FROM assets a
      WHERE (a.parent = ?1 OR (a.parent IS NULL AND ?1 IS NULL)) AND is_deleted = 0

      UNION ALL

      SELECT
          sa.uuid,
          sa.parent,
          sa.name,
          sa.type,
          sa.properties,
          sa.updated_at,
          sa.blob_size,
          sa.blob_version,
          sa.thumb_mime,
          at.depth + 1
      FROM assets sa
      JOIN asset_tree at
          ON sa.parent = at.uuid
      WHERE (at.type <> 0) AND is_deleted = 0 -- type != directory
  )
  SELECT
      uuid,
      parent,
      name,
      type,
      properties,
      updated_at,
      blob_size,
      blob_version,
      thumb_mime,
      depth
  FROM asset_tree
  ORDER BY depth, parent, name;
''';
  Stream<(Map<UUID, Asset> assets, List<FoldedAsset> roots)> watchAssetsInDirectory(UUID? directory) {
    return _db
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

  Future<(bool exists, int? mime)> getAssetBlobVersion(UUID uuid) async {
    if (isBuiltinAsset(uuid)) {
      final asset = _getBuiltinAsset(uuid);
      if (asset == null) return (false, null);
      return (true, asset.mockDatabaseAsset.blobVersion);
    }

    final rows = await _db.query(
      'SELECT blob_version FROM assets WHERE uuid = ?1 AND is_deleted = 0',
      [uuid],
    );
    if (rows.isEmpty) return (false, null);
    return (true, rows.first['blob_version'] as int?);
  }

  Future<(bool exists, String? mime)> getAssetThumbMime(UUID uuid) async {
    if (isBuiltinAsset(uuid)) {
      final asset = _getBuiltinAsset(uuid);
      if (asset == null) return (false, null);
      return (true, asset.mockDatabaseAsset.thumbMime);
    }

    final rows = await _db.query(
      'SELECT thumb_mime FROM assets WHERE uuid = ?1 AND is_deleted = 0',
      [uuid],
    );
    if (rows.isEmpty) return (false, null);
    return (true, rows.first['thumb_mime'] as String?);
  }

  (bool exists, String? uri) getAssetThumbUri(UUID uuid) {
    if (isBuiltinAsset(uuid)) {
      final asset = _getBuiltinAsset(uuid);
      if (asset == null) return (false, null);

      final path = asset.thumbPath;
      if (path == null) return (true, null);

      final uri = BuiltInResourceLoader.get().getUri(path);
      return (true, uri.toString());
    }

    return (
      true,
      Client.get().serverUri
          .replace(
            path: 'thumbs',
            queryParameters: {
              'project': Client.get().projectId,
              'uuid': uuid,
            },
          )
          .toString(),
    );
  }

  Future<void> transaction(Future<void> Function(CrdtExecutor txn) action) {
    return _db.transaction(action);
  }

  Future<void> execute(String sql, [List<Object?>? args]) {
    return _db.execute(sql, args);
  }

  BatchExecutor batch() {
    return _db.batch();
  }
}
