import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sl_shared/sl_shared.dart';

abstract interface class PathProvider {
  String getDatabasePath();
  String getAssetBlobPath(UUID uuid);
  String getAssetThumbPath(UUID uuid);
  String getSceneSavePath(UUID uuid);

  Future<void> dispose();
}

class RootedPathProvider implements PathProvider {
  final String _rootPath;

  RootedPathProvider({required String rootPath}) : _rootPath = rootPath;

  @override
  String getDatabasePath() {
    return p.join(_rootPath, 'db.sqlite3');
  }

  @override
  String getAssetBlobPath(UUID uuid) {
    return p.join(_rootPath, 'blobs', uuid);
  }

  @override
  String getAssetThumbPath(UUID uuid) {
    return p.join(_rootPath, 'thumbs', '$uuid.webp');
  }

  @override
  String getSceneSavePath(UUID uuid) {
    return p.join(_rootPath, 'scenes', '$uuid.json');
  }

  @override
  Future<void> dispose() async {}
}

class MixedTempPathProvider implements PathProvider {
  final RootedPathProvider _persistentPathProvider;
  final RootedPathProvider _tempPathProvider;
  final Set<UUID> _persistentUuids;

  MixedTempPathProvider({
    required String rootPath,
    required Set<UUID> persistentUuids,
  }) : _persistentPathProvider = RootedPathProvider(rootPath: rootPath),
       _tempPathProvider = RootedPathProvider(rootPath: p.join(rootPath, 'temp')),
       _persistentUuids = persistentUuids;

  PathProvider _getRelevantPathProvider(UUID uuid) {
    return _persistentUuids.contains(uuid) ? _persistentPathProvider : _tempPathProvider;
  }

  Future<void> clearTemp() async {
    final dir = Directory(_tempPathProvider._rootPath);
    if (!await dir.exists()) return;
    await dir.delete(recursive: true);
  }

  String getPersistentDatabasePath() {
    return _persistentPathProvider.getDatabasePath();
  }

  String getTempDatabasePath() {
    return _tempPathProvider.getDatabasePath();
  }

  @override
  String getDatabasePath() {
    return _tempPathProvider.getDatabasePath();
  }

  @override
  String getAssetBlobPath(UUID uuid) {
    return _getRelevantPathProvider(uuid).getAssetBlobPath(uuid);
  }

  @override
  String getAssetThumbPath(UUID uuid) {
    return _getRelevantPathProvider(uuid).getAssetThumbPath(uuid);
  }

  @override
  String getSceneSavePath(UUID uuid) {
    return _getRelevantPathProvider(uuid).getSceneSavePath(uuid);
  }

  @override
  Future<void> dispose() async {
    return await clearTemp();
  }
}
