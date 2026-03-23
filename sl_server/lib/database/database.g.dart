// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $AssetsTable extends Assets with TableInfo<$AssetsTable, Asset> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AssetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentMeta = const VerificationMeta('parent');
  @override
  late final GeneratedColumn<String> parent = GeneratedColumn<String>(
    'parent',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<AssetType, int> type =
      GeneratedColumn<int>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<AssetType>($AssetsTable.$convertertype);
  static const VerificationMeta _hasSubAssetsMeta = const VerificationMeta(
    'hasSubAssets',
  );
  @override
  late final GeneratedColumn<bool> hasSubAssets = GeneratedColumn<bool>(
    'has_sub_assets',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_sub_assets" IN (0, 1))',
    ),
  );
  static const VerificationMeta _propertiesMeta = const VerificationMeta(
    'properties',
  );
  @override
  late final GeneratedColumn<String> properties = GeneratedColumn<String>(
    'properties',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    uuid,
    parent,
    name,
    type,
    hasSubAssets,
    properties,
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
    if (data.containsKey('has_sub_assets')) {
      context.handle(
        _hasSubAssetsMeta,
        hasSubAssets.isAcceptableOrUnknown(
          data['has_sub_assets']!,
          _hasSubAssetsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_hasSubAssetsMeta);
    }
    if (data.containsKey('properties')) {
      context.handle(
        _propertiesMeta,
        properties.isAcceptableOrUnknown(data['properties']!, _propertiesMeta),
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
      type: $AssetsTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}type'],
        )!,
      ),
      hasSubAssets: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_sub_assets'],
      )!,
      properties: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}properties'],
      ),
    );
  }

  @override
  $AssetsTable createAlias(String alias) {
    return $AssetsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AssetType, int, int> $convertertype =
      const EnumIndexConverter<AssetType>(AssetType.values);
}

class Asset extends DataClass implements Insertable<Asset> {
  final String uuid;
  final String? parent;
  final String name;
  final AssetType type;
  final bool hasSubAssets;
  final String? properties;
  const Asset({
    required this.uuid,
    this.parent,
    required this.name,
    required this.type,
    required this.hasSubAssets,
    this.properties,
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
      map['type'] = Variable<int>($AssetsTable.$convertertype.toSql(type));
    }
    map['has_sub_assets'] = Variable<bool>(hasSubAssets);
    if (!nullToAbsent || properties != null) {
      map['properties'] = Variable<String>(properties);
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
      hasSubAssets: Value(hasSubAssets),
      properties: properties == null && nullToAbsent
          ? const Value.absent()
          : Value(properties),
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
      type: $AssetsTable.$convertertype.fromJson(
        serializer.fromJson<int>(json['type']),
      ),
      hasSubAssets: serializer.fromJson<bool>(json['hasSubAssets']),
      properties: serializer.fromJson<String?>(json['properties']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uuid': serializer.toJson<String>(uuid),
      'parent': serializer.toJson<String?>(parent),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<int>($AssetsTable.$convertertype.toJson(type)),
      'hasSubAssets': serializer.toJson<bool>(hasSubAssets),
      'properties': serializer.toJson<String?>(properties),
    };
  }

  Asset copyWith({
    String? uuid,
    Value<String?> parent = const Value.absent(),
    String? name,
    AssetType? type,
    bool? hasSubAssets,
    Value<String?> properties = const Value.absent(),
  }) => Asset(
    uuid: uuid ?? this.uuid,
    parent: parent.present ? parent.value : this.parent,
    name: name ?? this.name,
    type: type ?? this.type,
    hasSubAssets: hasSubAssets ?? this.hasSubAssets,
    properties: properties.present ? properties.value : this.properties,
  );
  Asset copyWithCompanion(AssetsCompanion data) {
    return Asset(
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      parent: data.parent.present ? data.parent.value : this.parent,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      hasSubAssets: data.hasSubAssets.present
          ? data.hasSubAssets.value
          : this.hasSubAssets,
      properties: data.properties.present
          ? data.properties.value
          : this.properties,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Asset(')
          ..write('uuid: $uuid, ')
          ..write('parent: $parent, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('hasSubAssets: $hasSubAssets, ')
          ..write('properties: $properties')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(uuid, parent, name, type, hasSubAssets, properties);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Asset &&
          other.uuid == this.uuid &&
          other.parent == this.parent &&
          other.name == this.name &&
          other.type == this.type &&
          other.hasSubAssets == this.hasSubAssets &&
          other.properties == this.properties);
}

class AssetsCompanion extends UpdateCompanion<Asset> {
  final Value<String> uuid;
  final Value<String?> parent;
  final Value<String> name;
  final Value<AssetType> type;
  final Value<bool> hasSubAssets;
  final Value<String?> properties;
  final Value<int> rowid;
  const AssetsCompanion({
    this.uuid = const Value.absent(),
    this.parent = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.hasSubAssets = const Value.absent(),
    this.properties = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AssetsCompanion.insert({
    required String uuid,
    this.parent = const Value.absent(),
    required String name,
    required AssetType type,
    required bool hasSubAssets,
    this.properties = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : uuid = Value(uuid),
       name = Value(name),
       type = Value(type),
       hasSubAssets = Value(hasSubAssets);
  static Insertable<Asset> custom({
    Expression<String>? uuid,
    Expression<String>? parent,
    Expression<String>? name,
    Expression<int>? type,
    Expression<bool>? hasSubAssets,
    Expression<String>? properties,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uuid != null) 'uuid': uuid,
      if (parent != null) 'parent': parent,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (hasSubAssets != null) 'has_sub_assets': hasSubAssets,
      if (properties != null) 'properties': properties,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AssetsCompanion copyWith({
    Value<String>? uuid,
    Value<String?>? parent,
    Value<String>? name,
    Value<AssetType>? type,
    Value<bool>? hasSubAssets,
    Value<String?>? properties,
    Value<int>? rowid,
  }) {
    return AssetsCompanion(
      uuid: uuid ?? this.uuid,
      parent: parent ?? this.parent,
      name: name ?? this.name,
      type: type ?? this.type,
      hasSubAssets: hasSubAssets ?? this.hasSubAssets,
      properties: properties ?? this.properties,
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
      map['type'] = Variable<int>(
        $AssetsTable.$convertertype.toSql(type.value),
      );
    }
    if (hasSubAssets.present) {
      map['has_sub_assets'] = Variable<bool>(hasSubAssets.value);
    }
    if (properties.present) {
      map['properties'] = Variable<String>(properties.value);
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
          ..write('hasSubAssets: $hasSubAssets, ')
          ..write('properties: $properties, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AssetRelationsTable extends AssetRelations
    with TableInfo<$AssetRelationsTable, AssetRelation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AssetRelationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _fromUuidMeta = const VerificationMeta(
    'fromUuid',
  );
  @override
  late final GeneratedColumn<String> fromUuid = GeneratedColumn<String>(
    'from_uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _toUuidMeta = const VerificationMeta('toUuid');
  @override
  late final GeneratedColumn<String> toUuid = GeneratedColumn<String>(
    'to_uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<AssetRelationType, int>
  relationType =
      GeneratedColumn<int>(
        'relation_type',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<AssetRelationType>(
        $AssetRelationsTable.$converterrelationType,
      );
  @override
  List<GeneratedColumn> get $columns => [id, fromUuid, toUuid, relationType];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'asset_relations';
  @override
  VerificationContext validateIntegrity(
    Insertable<AssetRelation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('from_uuid')) {
      context.handle(
        _fromUuidMeta,
        fromUuid.isAcceptableOrUnknown(data['from_uuid']!, _fromUuidMeta),
      );
    } else if (isInserting) {
      context.missing(_fromUuidMeta);
    }
    if (data.containsKey('to_uuid')) {
      context.handle(
        _toUuidMeta,
        toUuid.isAcceptableOrUnknown(data['to_uuid']!, _toUuidMeta),
      );
    } else if (isInserting) {
      context.missing(_toUuidMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AssetRelation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AssetRelation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      fromUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_uuid'],
      )!,
      toUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to_uuid'],
      )!,
      relationType: $AssetRelationsTable.$converterrelationType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}relation_type'],
        )!,
      ),
    );
  }

  @override
  $AssetRelationsTable createAlias(String alias) {
    return $AssetRelationsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AssetRelationType, int, int>
  $converterrelationType = const EnumIndexConverter<AssetRelationType>(
    AssetRelationType.values,
  );
}

class AssetRelation extends DataClass implements Insertable<AssetRelation> {
  final int id;
  final String fromUuid;
  final String toUuid;
  final AssetRelationType relationType;
  const AssetRelation({
    required this.id,
    required this.fromUuid,
    required this.toUuid,
    required this.relationType,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['from_uuid'] = Variable<String>(fromUuid);
    map['to_uuid'] = Variable<String>(toUuid);
    {
      map['relation_type'] = Variable<int>(
        $AssetRelationsTable.$converterrelationType.toSql(relationType),
      );
    }
    return map;
  }

  AssetRelationsCompanion toCompanion(bool nullToAbsent) {
    return AssetRelationsCompanion(
      id: Value(id),
      fromUuid: Value(fromUuid),
      toUuid: Value(toUuid),
      relationType: Value(relationType),
    );
  }

  factory AssetRelation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AssetRelation(
      id: serializer.fromJson<int>(json['id']),
      fromUuid: serializer.fromJson<String>(json['fromUuid']),
      toUuid: serializer.fromJson<String>(json['toUuid']),
      relationType: $AssetRelationsTable.$converterrelationType.fromJson(
        serializer.fromJson<int>(json['relationType']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'fromUuid': serializer.toJson<String>(fromUuid),
      'toUuid': serializer.toJson<String>(toUuid),
      'relationType': serializer.toJson<int>(
        $AssetRelationsTable.$converterrelationType.toJson(relationType),
      ),
    };
  }

  AssetRelation copyWith({
    int? id,
    String? fromUuid,
    String? toUuid,
    AssetRelationType? relationType,
  }) => AssetRelation(
    id: id ?? this.id,
    fromUuid: fromUuid ?? this.fromUuid,
    toUuid: toUuid ?? this.toUuid,
    relationType: relationType ?? this.relationType,
  );
  AssetRelation copyWithCompanion(AssetRelationsCompanion data) {
    return AssetRelation(
      id: data.id.present ? data.id.value : this.id,
      fromUuid: data.fromUuid.present ? data.fromUuid.value : this.fromUuid,
      toUuid: data.toUuid.present ? data.toUuid.value : this.toUuid,
      relationType: data.relationType.present
          ? data.relationType.value
          : this.relationType,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AssetRelation(')
          ..write('id: $id, ')
          ..write('fromUuid: $fromUuid, ')
          ..write('toUuid: $toUuid, ')
          ..write('relationType: $relationType')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, fromUuid, toUuid, relationType);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AssetRelation &&
          other.id == this.id &&
          other.fromUuid == this.fromUuid &&
          other.toUuid == this.toUuid &&
          other.relationType == this.relationType);
}

class AssetRelationsCompanion extends UpdateCompanion<AssetRelation> {
  final Value<int> id;
  final Value<String> fromUuid;
  final Value<String> toUuid;
  final Value<AssetRelationType> relationType;
  const AssetRelationsCompanion({
    this.id = const Value.absent(),
    this.fromUuid = const Value.absent(),
    this.toUuid = const Value.absent(),
    this.relationType = const Value.absent(),
  });
  AssetRelationsCompanion.insert({
    this.id = const Value.absent(),
    required String fromUuid,
    required String toUuid,
    required AssetRelationType relationType,
  }) : fromUuid = Value(fromUuid),
       toUuid = Value(toUuid),
       relationType = Value(relationType);
  static Insertable<AssetRelation> custom({
    Expression<int>? id,
    Expression<String>? fromUuid,
    Expression<String>? toUuid,
    Expression<int>? relationType,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fromUuid != null) 'from_uuid': fromUuid,
      if (toUuid != null) 'to_uuid': toUuid,
      if (relationType != null) 'relation_type': relationType,
    });
  }

  AssetRelationsCompanion copyWith({
    Value<int>? id,
    Value<String>? fromUuid,
    Value<String>? toUuid,
    Value<AssetRelationType>? relationType,
  }) {
    return AssetRelationsCompanion(
      id: id ?? this.id,
      fromUuid: fromUuid ?? this.fromUuid,
      toUuid: toUuid ?? this.toUuid,
      relationType: relationType ?? this.relationType,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (fromUuid.present) {
      map['from_uuid'] = Variable<String>(fromUuid.value);
    }
    if (toUuid.present) {
      map['to_uuid'] = Variable<String>(toUuid.value);
    }
    if (relationType.present) {
      map['relation_type'] = Variable<int>(
        $AssetRelationsTable.$converterrelationType.toSql(relationType.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AssetRelationsCompanion(')
          ..write('id: $id, ')
          ..write('fromUuid: $fromUuid, ')
          ..write('toUuid: $toUuid, ')
          ..write('relationType: $relationType')
          ..write(')'))
        .toString();
  }
}

abstract class _$Database extends GeneratedDatabase {
  _$Database(QueryExecutor e) : super(e);
  $DatabaseManager get managers => $DatabaseManager(this);
  late final $AssetsTable assets = $AssetsTable(this);
  late final $AssetRelationsTable assetRelations = $AssetRelationsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [assets, assetRelations];
}

typedef $$AssetsTableCreateCompanionBuilder =
    AssetsCompanion Function({
      required String uuid,
      Value<String?> parent,
      required String name,
      required AssetType type,
      required bool hasSubAssets,
      Value<String?> properties,
      Value<int> rowid,
    });
typedef $$AssetsTableUpdateCompanionBuilder =
    AssetsCompanion Function({
      Value<String> uuid,
      Value<String?> parent,
      Value<String> name,
      Value<AssetType> type,
      Value<bool> hasSubAssets,
      Value<String?> properties,
      Value<int> rowid,
    });

class $$AssetsTableFilterComposer extends Composer<_$Database, $AssetsTable> {
  $$AssetsTableFilterComposer({
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

  ColumnFilters<bool> get hasSubAssets => $composableBuilder(
    column: $table.hasSubAssets,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get properties => $composableBuilder(
    column: $table.properties,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AssetsTableOrderingComposer extends Composer<_$Database, $AssetsTable> {
  $$AssetsTableOrderingComposer({
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

  ColumnOrderings<bool> get hasSubAssets => $composableBuilder(
    column: $table.hasSubAssets,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get properties => $composableBuilder(
    column: $table.properties,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AssetsTableAnnotationComposer
    extends Composer<_$Database, $AssetsTable> {
  $$AssetsTableAnnotationComposer({
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

  GeneratedColumn<bool> get hasSubAssets => $composableBuilder(
    column: $table.hasSubAssets,
    builder: (column) => column,
  );

  GeneratedColumn<String> get properties => $composableBuilder(
    column: $table.properties,
    builder: (column) => column,
  );
}

class $$AssetsTableTableManager
    extends
        RootTableManager<
          _$Database,
          $AssetsTable,
          Asset,
          $$AssetsTableFilterComposer,
          $$AssetsTableOrderingComposer,
          $$AssetsTableAnnotationComposer,
          $$AssetsTableCreateCompanionBuilder,
          $$AssetsTableUpdateCompanionBuilder,
          (Asset, BaseReferences<_$Database, $AssetsTable, Asset>),
          Asset,
          PrefetchHooks Function()
        > {
  $$AssetsTableTableManager(_$Database db, $AssetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AssetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AssetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AssetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> uuid = const Value.absent(),
                Value<String?> parent = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<AssetType> type = const Value.absent(),
                Value<bool> hasSubAssets = const Value.absent(),
                Value<String?> properties = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AssetsCompanion(
                uuid: uuid,
                parent: parent,
                name: name,
                type: type,
                hasSubAssets: hasSubAssets,
                properties: properties,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String uuid,
                Value<String?> parent = const Value.absent(),
                required String name,
                required AssetType type,
                required bool hasSubAssets,
                Value<String?> properties = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AssetsCompanion.insert(
                uuid: uuid,
                parent: parent,
                name: name,
                type: type,
                hasSubAssets: hasSubAssets,
                properties: properties,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AssetsTableProcessedTableManager =
    ProcessedTableManager<
      _$Database,
      $AssetsTable,
      Asset,
      $$AssetsTableFilterComposer,
      $$AssetsTableOrderingComposer,
      $$AssetsTableAnnotationComposer,
      $$AssetsTableCreateCompanionBuilder,
      $$AssetsTableUpdateCompanionBuilder,
      (Asset, BaseReferences<_$Database, $AssetsTable, Asset>),
      Asset,
      PrefetchHooks Function()
    >;
typedef $$AssetRelationsTableCreateCompanionBuilder =
    AssetRelationsCompanion Function({
      Value<int> id,
      required String fromUuid,
      required String toUuid,
      required AssetRelationType relationType,
    });
typedef $$AssetRelationsTableUpdateCompanionBuilder =
    AssetRelationsCompanion Function({
      Value<int> id,
      Value<String> fromUuid,
      Value<String> toUuid,
      Value<AssetRelationType> relationType,
    });

class $$AssetRelationsTableFilterComposer
    extends Composer<_$Database, $AssetRelationsTable> {
  $$AssetRelationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fromUuid => $composableBuilder(
    column: $table.fromUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toUuid => $composableBuilder(
    column: $table.toUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<AssetRelationType, AssetRelationType, int>
  get relationType => $composableBuilder(
    column: $table.relationType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );
}

class $$AssetRelationsTableOrderingComposer
    extends Composer<_$Database, $AssetRelationsTable> {
  $$AssetRelationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fromUuid => $composableBuilder(
    column: $table.fromUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toUuid => $composableBuilder(
    column: $table.toUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get relationType => $composableBuilder(
    column: $table.relationType,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AssetRelationsTableAnnotationComposer
    extends Composer<_$Database, $AssetRelationsTable> {
  $$AssetRelationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fromUuid =>
      $composableBuilder(column: $table.fromUuid, builder: (column) => column);

  GeneratedColumn<String> get toUuid =>
      $composableBuilder(column: $table.toUuid, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AssetRelationType, int> get relationType =>
      $composableBuilder(
        column: $table.relationType,
        builder: (column) => column,
      );
}

class $$AssetRelationsTableTableManager
    extends
        RootTableManager<
          _$Database,
          $AssetRelationsTable,
          AssetRelation,
          $$AssetRelationsTableFilterComposer,
          $$AssetRelationsTableOrderingComposer,
          $$AssetRelationsTableAnnotationComposer,
          $$AssetRelationsTableCreateCompanionBuilder,
          $$AssetRelationsTableUpdateCompanionBuilder,
          (
            AssetRelation,
            BaseReferences<_$Database, $AssetRelationsTable, AssetRelation>,
          ),
          AssetRelation,
          PrefetchHooks Function()
        > {
  $$AssetRelationsTableTableManager(_$Database db, $AssetRelationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AssetRelationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AssetRelationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AssetRelationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> fromUuid = const Value.absent(),
                Value<String> toUuid = const Value.absent(),
                Value<AssetRelationType> relationType = const Value.absent(),
              }) => AssetRelationsCompanion(
                id: id,
                fromUuid: fromUuid,
                toUuid: toUuid,
                relationType: relationType,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String fromUuid,
                required String toUuid,
                required AssetRelationType relationType,
              }) => AssetRelationsCompanion.insert(
                id: id,
                fromUuid: fromUuid,
                toUuid: toUuid,
                relationType: relationType,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AssetRelationsTableProcessedTableManager =
    ProcessedTableManager<
      _$Database,
      $AssetRelationsTable,
      AssetRelation,
      $$AssetRelationsTableFilterComposer,
      $$AssetRelationsTableOrderingComposer,
      $$AssetRelationsTableAnnotationComposer,
      $$AssetRelationsTableCreateCompanionBuilder,
      $$AssetRelationsTableUpdateCompanionBuilder,
      (
        AssetRelation,
        BaseReferences<_$Database, $AssetRelationsTable, AssetRelation>,
      ),
      AssetRelation,
      PrefetchHooks Function()
    >;

class $DatabaseManager {
  final _$Database _db;
  $DatabaseManager(this._db);
  $$AssetsTableTableManager get assets =>
      $$AssetsTableTableManager(_db, _db.assets);
  $$AssetRelationsTableTableManager get assetRelations =>
      $$AssetRelationsTableTableManager(_db, _db.assetRelations);
}
