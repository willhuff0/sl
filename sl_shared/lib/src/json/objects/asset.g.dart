// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AssetEntry _$AssetEntryFromJson(Map<String, dynamic> json) => AssetEntry(
  uuid: json['uuid'] as String,
  name: json['name'] as String,
  type: $enumDecode(_$AssetTypeEnumMap, json['type']),
  subAssets: (json['subAssets'] as List<dynamic>)
      .map((e) => AssetEntry.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$AssetEntryToJson(AssetEntry instance) =>
    <String, dynamic>{
      'uuid': instance.uuid,
      'name': instance.name,
      'type': _$AssetTypeEnumMap[instance.type]!,
      'subAssets': instance.subAssets,
    };

const _$AssetTypeEnumMap = {
  AssetType.directory: 'directory',
  AssetType.unsupported: 'unsupported',
  AssetType.propertiesOnly: 'propertiesOnly',
  AssetType.texture: 'texture',
  AssetType.mesh: 'mesh',
  AssetType.model: 'model',
  AssetType.shader: 'shader',
  AssetType.nodeTree: 'nodeTree',
};
