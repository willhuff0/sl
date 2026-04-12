import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sl_shared/sl_shared.dart';

part 'database.g.dart';

@DriftDatabase(
  include: {
    'database.drift',
  },
)
class Database extends _$Database {
  Database(String path, [QueryExecutor? executor]) : super(executor ?? _openConnection(path));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (_) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  static QueryExecutor _openConnection(String path) {
    return NativeDatabase.createInBackground(File(path), logStatements: true);
  }
}
