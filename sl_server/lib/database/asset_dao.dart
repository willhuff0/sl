import 'package:drift/drift.dart';
import 'package:sl_server/database/database.dart';
import 'package:sl_shared/sl_shared.dart';

Future<List<AssetEntry>> getAssetEntriesInDirectory(Database db, UUID directory) async {
  final assets =
      await (db.selectOnly(db.assets)
            ..addColumns([
              db.assets.uuid,
              db.assets.parent,
              db.assets.name,
              db.assets.type,
              db.assets.hasSubAssets,
            ])
            ..where(db.assets.parent.equals(directory)))
          .get();

  final subassets =
      await (db.selectOnly(db.assets)
            ..addColumns([
              db.assets.uuid,
              db.assets.parent,
              db.assets.name,
              db.assets.type,
              db.assets.hasSubAssets,
            ])
            ..join([
              innerJoin(other, on)
            ]))
          .get();
}
