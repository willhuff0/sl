import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sl_shared/sl_shared.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Assets, AssetRelations])
class Database extends _$Database {
  Database(String path, [QueryExecutor? executor]) : super(executor ?? _openConnection(path));

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection(String path) {
    return NativeDatabase.createInBackground(File(path));
  }

  Future<Asset> getAsset(UUID uuid) async {
    return await (select(assets)..where((e) => e.uuid.equals(uuid))).getSingle();
  }

  Future<List<Asset>> getAssetsInDirectory(UUID uuid) async {
    return await (select(assets)..where((e) => e.parent.equals(uuid))).get();
  }
}

class Assets extends Table {
  late final uuid = text()();
  late final parent = text().nullable()();
  late final name = text()();
  late final type = intEnum<AssetType>()();

  late final hasSubAssets = boolean()();

  late final properties = text().nullable()();

  @override
  Set<Column<Object>>? get primaryKey => {uuid};

  @override
  List<String> get customConstraints => ['FOREIGN KEY (parent) REFERENCES assets (uuid)'];
}

enum AssetRelationType {
  dependsOn,
  subAssetOf,
}

class AssetRelations extends Table {
  late final id = integer().autoIncrement()();
  late final fromUuid = text()();
  late final toUuid = text()();
  late final relationType = intEnum<AssetRelationType>()();

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (from_uuid) REFERENCES assets (uuid)',
    'FOREIGN KEY (to_uuid) REFERENCES assets (uuid)',
  ];
}
