import 'package:sembast_web/sembast_web.dart';
import 'package:sl_shared/sl_shared.dart';

class LocalAssetEntry {
  final UUID uuid;
  final int? blobSize;
  final DateTime? blobUpdatedAt;

  final int? downloadProgress;

  LocalAssetEntry({
    required this.uuid,
    required this.blobSize,
    required this.blobUpdatedAt,
    required this.downloadProgress,
  });

  factory LocalAssetEntry.fromSembast(Map<String, Object?> s) => LocalAssetEntry(
    uuid: s['uuid'] as String,
    blobSize: s['blobSize'] as int?,
    blobUpdatedAt: () {
      final v = s['blobUpdatedAt'] as String?;
      if (v == null) return null;
      return DateTime.parse(v);
    }(),
    downloadProgress: s['downloadProgress'] as int?,
  );

  Map<String, Object?> toSembast() => {
    'uuid': uuid,
    'blobSize': ?blobSize,
    'blobUpdatedAt': ?blobUpdatedAt?.toIso8601String(),
    'downloadProgress': ?downloadProgress,
  };
}

class LocalAssetDatabase {
  static final _store = stringMapStoreFactory.store();
  static final _factory = databaseFactoryWeb;

  final Database _db;

  LocalAssetDatabase._(this._db);
  static Future<LocalAssetDatabase> open(UUID projectId) async {
    final db = await _factory.openDatabase(projectId);
    return LocalAssetDatabase._(db);
  }

  Future<LocalAssetEntry?> getAsset(UUID uuid) async {
    final record = await _store.record(uuid).get(_db);
    if (record == null) return null;
    return LocalAssetEntry.fromSembast(record);
  }

  Future<void> setAssetBlobSizeAndClearDownloadProgress(UUID uuid, int? blobSize) async {
    await _store.record(uuid).put(_db, {
      'uuid': uuid,
      'blobSize': blobSize,
      'blobUpdatedAt': DateTime.now().toIso8601String(),
      'downloadProgress': null,
    }, merge: true);
  }

  Future<void> setAssetDownloadProgress(UUID uuid, int? downloadProgress) async {
    await _store.record(uuid).put(_db, {
      'uuid': uuid,
      'downloadProgress': downloadProgress,
    }, merge: true);
  }
}
