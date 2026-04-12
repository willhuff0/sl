// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class Assets extends Table with TableInfo<Assets, Asset> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Assets(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _parentMeta = const VerificationMeta('parent');
  late final GeneratedColumn<String> parent = GeneratedColumn<String>(
    'parent',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES assets(uuid)',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  late final GeneratedColumnWithTypeConverter<AssetType, int> type =
      GeneratedColumn<int>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL',
      ).withConverter<AssetType>(Assets.$convertertype);
  static const VerificationMeta _propertiesMeta = const VerificationMeta(
    'properties',
  );
  late final GeneratedColumn<String> properties = GeneratedColumn<String>(
    'properties',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _blobSizeMeta = const VerificationMeta(
    'blobSize',
  );
  late final GeneratedColumn<int> blobSize = GeneratedColumn<int>(
    'blob_size',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _blobUpdatedAtMeta = const VerificationMeta(
    'blobUpdatedAt',
  );
  late final GeneratedColumn<String> blobUpdatedAt = GeneratedColumn<String>(
    'blob_updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    uuid,
    parent,
    name,
    type,
    properties,
    updatedAt,
    blobSize,
    blobUpdatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'assets';
  @override
  VerificationContext validateIntegrity(
    Insertable<Asset> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('parent')) {
      context.handle(
        _parentMeta,
        parent.isAcceptableOrUnknown(data['parent']!, _parentMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('properties')) {
      context.handle(
        _propertiesMeta,
        properties.isAcceptableOrUnknown(data['properties']!, _propertiesMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('blob_size')) {
      context.handle(
        _blobSizeMeta,
        blobSize.isAcceptableOrUnknown(data['blob_size']!, _blobSizeMeta),
      );
    }
    if (data.containsKey('blob_updated_at')) {
      context.handle(
        _blobUpdatedAtMeta,
        blobUpdatedAt.isAcceptableOrUnknown(
          data['blob_updated_at']!,
          _blobUpdatedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uuid};
  @override
  Asset map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Asset(
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      parent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: Assets.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}type'],
        )!,
      ),
      properties: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}properties'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      ),
      blobSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}blob_size'],
      ),
      blobUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}blob_updated_at'],
      ),
    );
  }

  @override
  Assets createAlias(String alias) {
    return Assets(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AssetType, int, int> $convertertype =
      const EnumIndexConverter<AssetType>(AssetType.values);
  @override
  bool get dontWriteConstraints => true;
}

class Asset extends DataClass implements Insertable<Asset> {
  final String uuid;
  final String? parent;
  final String name;
  final AssetType type;
  final String? properties;
  final String? updatedAt;
  final int? blobSize;
  final String? blobUpdatedAt;
  const Asset({
    required this.uuid,
    this.parent,
    required this.name,
    required this.type,
    this.properties,
    this.updatedAt,
    this.blobSize,
    this.blobUpdatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uuid'] = Variable<String>(uuid);
    if (!nullToAbsent || parent != null) {
      map['parent'] = Variable<String>(parent);
    }
    map['name'] = Variable<String>(name);
    {
      map['type'] = Variable<int>(Assets.$convertertype.toSql(type));
    }
    if (!nullToAbsent || properties != null) {
      map['properties'] = Variable<String>(properties);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<String>(updatedAt);
    }
    if (!nullToAbsent || blobSize != null) {
      map['blob_size'] = Variable<int>(blobSize);
    }
    if (!nullToAbsent || blobUpdatedAt != null) {
      map['blob_updated_at'] = Variable<String>(blobUpdatedAt);
    }
    return map;
  }

  AssetsCompanion toCompanion(bool nullToAbsent) {
    return AssetsCompanion(
      uuid: Value(uuid),
      parent: parent == null && nullToAbsent
          ? const Value.absent()
          : Value(parent),
      name: Value(name),
      type: Value(type),
      properties: properties == null && nullToAbsent
          ? const Value.absent()
          : Value(properties),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      blobSize: blobSize == null && nullToAbsent
          ? const Value.absent()
          : Value(blobSize),
      blobUpdatedAt: blobUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(blobUpdatedAt),
    );
  }

  factory Asset.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Asset(
      uuid: serializer.fromJson<String>(json['uuid']),
      parent: serializer.fromJson<String?>(json['parent']),
      name: serializer.fromJson<String>(json['name']),
      type: Assets.$convertertype.fromJson(
        serializer.fromJson<int>(json['type']),
      ),
      properties: serializer.fromJson<String?>(json['properties']),
      updatedAt: serializer.fromJson<String?>(json['updated_at']),
      blobSize: serializer.fromJson<int?>(json['blob_size']),
      blobUpdatedAt: serializer.fromJson<String?>(json['blob_updated_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uuid': serializer.toJson<String>(uuid),
      'parent': serializer.toJson<String?>(parent),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<int>(Assets.$convertertype.toJson(type)),
      'properties': serializer.toJson<String?>(properties),
      'updated_at': serializer.toJson<String?>(updatedAt),
      'blob_size': serializer.toJson<int?>(blobSize),
      'blob_updated_at': serializer.toJson<String?>(blobUpdatedAt),
    };
  }

  Asset copyWith({
    String? uuid,
    Value<String?> parent = const Value.absent(),
    String? name,
    AssetType? type,
    Value<String?> properties = const Value.absent(),
    Value<String?> updatedAt = const Value.absent(),
    Value<int?> blobSize = const Value.absent(),
    Value<String?> blobUpdatedAt = const Value.absent(),
  }) => Asset(
    uuid: uuid ?? this.uuid,
    parent: parent.present ? parent.value : this.parent,
    name: name ?? this.name,
    type: type ?? this.type,
    properties: properties.present ? properties.value : this.properties,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    blobSize: blobSize.present ? blobSize.value : this.blobSize,
    blobUpdatedAt: blobUpdatedAt.present
        ? blobUpdatedAt.value
        : this.blobUpdatedAt,
  );
  Asset copyWithCompanion(AssetsCompanion data) {
    return Asset(
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      parent: data.parent.present ? data.parent.value : this.parent,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      properties: data.properties.present
          ? data.properties.value
          : this.properties,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      blobSize: data.blobSize.present ? data.blobSize.value : this.blobSize,
      blobUpdatedAt: data.blobUpdatedAt.present
          ? data.blobUpdatedAt.value
          : this.blobUpdatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Asset(')
          ..write('uuid: $uuid, ')
          ..write('parent: $parent, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('properties: $properties, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('blobSize: $blobSize, ')
          ..write('blobUpdatedAt: $blobUpdatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    uuid,
    parent,
    name,
    type,
    properties,
    updatedAt,
    blobSize,
    blobUpdatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Asset &&
          other.uuid == this.uuid &&
          other.parent == this.parent &&
          other.name == this.name &&
          other.type == this.type &&
          other.properties == this.properties &&
          other.updatedAt == this.updatedAt &&
          other.blobSize == this.blobSize &&
          other.blobUpdatedAt == this.blobUpdatedAt);
}

class AssetsCompanion extends UpdateCompanion<Asset> {
  final Value<String> uuid;
  final Value<String?> parent;
  final Value<String> name;
  final Value<AssetType> type;
  final Value<String?> properties;
  final Value<String?> updatedAt;
  final Value<int?> blobSize;
  final Value<String?> blobUpdatedAt;
  final Value<int> rowid;
  const AssetsCompanion({
    this.uuid = const Value.absent(),
    this.parent = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.properties = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.blobSize = const Value.absent(),
    this.blobUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AssetsCompanion.insert({
    required String uuid,
    this.parent = const Value.absent(),
    required String name,
    required AssetType type,
    this.properties = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.blobSize = const Value.absent(),
    this.blobUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : uuid = Value(uuid),
       name = Value(name),
       type = Value(type);
  static Insertable<Asset> custom({
    Expression<String>? uuid,
    Expression<String>? parent,
    Expression<String>? name,
    Expression<int>? type,
    Expression<String>? properties,
    Expression<String>? updatedAt,
    Expression<int>? blobSize,
    Expression<String>? blobUpdatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uuid != null) 'uuid': uuid,
      if (parent != null) 'parent': parent,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (properties != null) 'properties': properties,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (blobSize != null) 'blob_size': blobSize,
      if (blobUpdatedAt != null) 'blob_updated_at': blobUpdatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AssetsCompanion copyWith({
    Value<String>? uuid,
    Value<String?>? parent,
    Value<String>? name,
    Value<AssetType>? type,
    Value<String?>? properties,
    Value<String?>? updatedAt,
    Value<int?>? blobSize,
    Value<String?>? blobUpdatedAt,
    Value<int>? rowid,
  }) {
    return AssetsCompanion(
      uuid: uuid ?? this.uuid,
      parent: parent ?? this.parent,
      name: name ?? this.name,
      type: type ?? this.type,
      properties: properties ?? this.properties,
      updatedAt: updatedAt ?? this.updatedAt,
      blobSize: blobSize ?? this.blobSize,
      blobUpdatedAt: blobUpdatedAt ?? this.blobUpdatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (parent.present) {
      map['parent'] = Variable<String>(parent.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<int>(Assets.$convertertype.toSql(type.value));
    }
    if (properties.present) {
      map['properties'] = Variable<String>(properties.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (blobSize.present) {
      map['blob_size'] = Variable<int>(blobSize.value);
    }
    if (blobUpdatedAt.present) {
      map['blob_updated_at'] = Variable<String>(blobUpdatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AssetsCompanion(')
          ..write('uuid: $uuid, ')
          ..write('parent: $parent, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('properties: $properties, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('blobSize: $blobSize, ')
          ..write('blobUpdatedAt: $blobUpdatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$Database extends GeneratedDatabase {
  _$Database(QueryExecutor e) : super(e);
  $DatabaseManager get managers => $DatabaseManager(this);
  late final Assets assets = Assets(this);
  late final Index idxAssetsParent = Index(
    'idx_assets_parent',
    'CREATE INDEX idx_assets_parent ON assets (parent)',
  );
  Selectable<Asset> getAssetByUUID(String uuid) {
    return customSelect(
      'SELECT * FROM assets WHERE uuid = ?1',
      variables: [Variable<String>(uuid)],
      readsFrom: {assets},
    ).asyncMap(assets.mapFromRow);
  }

  Selectable<GetAssetsInDirectoryResult> getAssetsInDirectory(
    String? directoryUuid,
  ) {
    return customSelect(
      'WITH RECURSIVE asset_tree AS (SELECT a.uuid, a.parent, a.name, a.type, a.properties, a.updated_at, a.blob_size, a.blob_updated_at, 0 AS depth FROM assets AS a WHERE a.parent = ?1 OR(a.parent IS NULL AND ?1 IS NULL)UNION ALL SELECT sa.uuid, sa.parent, sa.name, sa.type, sa.properties, sa.updated_at, sa.blob_size, sa.blob_updated_at, at.depth + 1 FROM assets AS sa JOIN asset_tree AS at ON sa.parent = at.uuid WHERE at.type <> 0) SELECT uuid, parent, name, type, properties, updated_at, blob_size, blob_updated_at, depth FROM asset_tree ORDER BY depth, parent, name',
      variables: [Variable<String>(directoryUuid)],
      readsFrom: {assets},
    ).map(
      (QueryRow row) => GetAssetsInDirectoryResult(
        uuid: row.read<String>('uuid'),
        parent: row.readNullable<String>('parent'),
        name: row.read<String>('name'),
        type: Assets.$convertertype.fromSql(row.read<int>('type')),
        properties: row.readNullable<String>('properties'),
        updatedAt: row.readNullable<String>('updated_at'),
        blobSize: row.readNullable<int>('blob_size'),
        blobUpdatedAt: row.readNullable<String>('blob_updated_at'),
        depth: row.read<int>('depth'),
      ),
    );
  }

  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [assets, idxAssetsParent];
}

typedef $AssetsCreateCompanionBuilder =
    AssetsCompanion Function({
      required String uuid,
      Value<String?> parent,
      required String name,
      required AssetType type,
      Value<String?> properties,
      Value<String?> updatedAt,
      Value<int?> blobSize,
      Value<String?> blobUpdatedAt,
      Value<int> rowid,
    });
typedef $AssetsUpdateCompanionBuilder =
    AssetsCompanion Function({
      Value<String> uuid,
      Value<String?> parent,
      Value<String> name,
      Value<AssetType> type,
      Value<String?> properties,
      Value<String?> updatedAt,
      Value<int?> blobSize,
      Value<String?> blobUpdatedAt,
      Value<int> rowid,
    });

class $AssetsFilterComposer extends Composer<_$Database, Assets> {
  $AssetsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parent => $composableBuilder(
    column: $table.parent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<AssetType, AssetType, int> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get properties => $composableBuilder(
    column: $table.properties,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get blobSize => $composableBuilder(
    column: $table.blobSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get blobUpdatedAt => $composableBuilder(
    column: $table.blobUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $AssetsOrderingComposer extends Composer<_$Database, Assets> {
  $AssetsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parent => $composableBuilder(
    column: $table.parent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get properties => $composableBuilder(
    column: $table.properties,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get blobSize => $composableBuilder(
    column: $table.blobSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get blobUpdatedAt => $composableBuilder(
    column: $table.blobUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $AssetsAnnotationComposer extends Composer<_$Database, Assets> {
  $AssetsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get parent =>
      $composableBuilder(column: $table.parent, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AssetType, int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get properties => $composableBuilder(
    column: $table.properties,
    builder: (column) => column,
  );

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get blobSize =>
      $composableBuilder(column: $table.blobSize, builder: (column) => column);

  GeneratedColumn<String> get blobUpdatedAt => $composableBuilder(
    column: $table.blobUpdatedAt,
    builder: (column) => column,
  );
}

class $AssetsTableManager
    extends
        RootTableManager<
          _$Database,
          Assets,
          Asset,
          $AssetsFilterComposer,
          $AssetsOrderingComposer,
          $AssetsAnnotationComposer,
          $AssetsCreateCompanionBuilder,
          $AssetsUpdateCompanionBuilder,
          (Asset, BaseReferences<_$Database, Assets, Asset>),
          Asset,
          PrefetchHooks Function()
        > {
  $AssetsTableManager(_$Database db, Assets table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $AssetsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $AssetsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $AssetsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> uuid = const Value.absent(),
                Value<String?> parent = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<AssetType> type = const Value.absent(),
                Value<String?> properties = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<int?> blobSize = const Value.absent(),
                Value<String?> blobUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AssetsCompanion(
                uuid: uuid,
                parent: parent,
                name: name,
                type: type,
                properties: properties,
                updatedAt: updatedAt,
                blobSize: blobSize,
                blobUpdatedAt: blobUpdatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String uuid,
                Value<String?> parent = const Value.absent(),
                required String name,
                required AssetType type,
                Value<String?> properties = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<int?> blobSize = const Value.absent(),
                Value<String?> blobUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AssetsCompanion.insert(
                uuid: uuid,
                parent: parent,
                name: name,
                type: type,
                properties: properties,
                updatedAt: updatedAt,
                blobSize: blobSize,
                blobUpdatedAt: blobUpdatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $AssetsProcessedTableManager =
    ProcessedTableManager<
      _$Database,
      Assets,
      Asset,
      $AssetsFilterComposer,
      $AssetsOrderingComposer,
      $AssetsAnnotationComposer,
      $AssetsCreateCompanionBuilder,
      $AssetsUpdateCompanionBuilder,
      (Asset, BaseReferences<_$Database, Assets, Asset>),
      Asset,
      PrefetchHooks Function()
    >;

class $DatabaseManager {
  final _$Database _db;
  $DatabaseManager(this._db);
  $AssetsTableManager get assets => $AssetsTableManager(_db, _db.assets);
}

class GetAssetsInDirectoryResult {
  final String uuid;
  final String? parent;
  final String name;
  final AssetType type;
  final String? properties;
  final String? updatedAt;
  final int? blobSize;
  final String? blobUpdatedAt;
  final int depth;
  GetAssetsInDirectoryResult({
    required this.uuid,
    this.parent,
    required this.name,
    required this.type,
    this.properties,
    this.updatedAt,
    this.blobSize,
    this.blobUpdatedAt,
    required this.depth,
  });
}
