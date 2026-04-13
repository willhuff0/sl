import 'dart:convert';

import 'package:sl_shared/sl_shared.dart';

class Asset {
  final UUID uuid;
  final UUID? parent;
  final String name;
  final AssetType type;
  final dynamic properties;
  final DateTime updatedAt;
  final int? blobSize;
  final DateTime blobUpdatedAt;

  Asset({
    required this.uuid,
    required this.parent,
    required this.name,
    required this.type,
    required this.properties,
    required this.updatedAt,
    required this.blobSize,
    required this.blobUpdatedAt,
  });

  Map<String, Object?> serialize() => {
    'uuid': uuid,
    'parent': ?parent,
    'name': name,
    'type': type.name,
    if (properties != null) 'properties': jsonEncode(properties),
    'updated_at': updatedAt.toIso8601String(),
    'blob_size': ?blobSize,
    'blob_updated_at': blobUpdatedAt.toIso8601String(),
  };
  factory Asset.deserialize(Map<String, Object?> v) => Asset(
    uuid: v['uuid'] as String,
    parent: v['parent'] as String?,
    name: v['name'] as String,
    type: AssetType.values.byName(v['type'] as String),
    properties: () {
      final encoded = v['properties'] as String?;
      if (encoded == null) return null;
      return jsonDecode(encoded);
    }(),
    updatedAt: DateTime.parse(v['updated_at'] as String),
    blobSize: v['blob_size'] as int?,
    blobUpdatedAt: DateTime.parse(v['blob_updated_at'] as String),
  );
}

class FoldedAsset {
  final UUID uuid;
  final List<FoldedAsset> subAssets;

  FoldedAsset({
    required this.uuid,
    required this.subAssets,
  });
}
