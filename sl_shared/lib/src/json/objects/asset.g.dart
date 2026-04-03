// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AssetCreateInfo _$AssetCreateInfoFromJson(Map<String, dynamic> json) =>
    AssetCreateInfo(
      uuid: json['uuid'] as String,
      parent: json['parent'] as String?,
      name: json['name'] as String,
      type: $enumDecode(_$AssetTypeEnumMap, json['type']),
    );

Map<String, dynamic> _$AssetCreateInfoToJson(AssetCreateInfo instance) =>
    <String, dynamic>{
      'uuid': instance.uuid,
      'parent': instance.parent,
      'name': instance.name,
      'type': _$AssetTypeEnumMap[instance.type]!,
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

AssetEntry _$AssetEntryFromJson(Map<String, dynamic> json) => AssetEntry(
  uuid: json['uuid'] as String,
  name: json['name'] as String,
  type: $enumDecode(_$AssetTypeEnumMap, json['type']),
  subAssets: (json['subAssets'] as List<dynamic>)
      .map((e) => AssetEntry.fromJson(e as Map<String, dynamic>))
      .toList(),
  blobSize: (json['blobSize'] as num?)?.toInt(),
);

Map<String, dynamic> _$AssetEntryToJson(AssetEntry instance) =>
    <String, dynamic>{
      'uuid': instance.uuid,
      'name': instance.name,
      'type': _$AssetTypeEnumMap[instance.type]!,
      'subAssets': instance.subAssets,
      'blobSize': instance.blobSize,
    };

CtsCreateAssets _$CtsCreateAssetsFromJson(Map<String, dynamic> json) =>
    CtsCreateAssets(
      createInfos: (json['createInfos'] as List<dynamic>)
          .map((e) => AssetCreateInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CtsCreateAssetsToJson(CtsCreateAssets instance) =>
    <String, dynamic>{'createInfos': instance.createInfos};

CtsDeleteAssets _$CtsDeleteAssetsFromJson(Map<String, dynamic> json) =>
    CtsDeleteAssets(
      uuids: (json['uuids'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$CtsDeleteAssetsToJson(CtsDeleteAssets instance) =>
    <String, dynamic>{'uuids': instance.uuids};

CtsListenToAssetDirectory _$CtsListenToAssetDirectoryFromJson(
  Map<String, dynamic> json,
) => CtsListenToAssetDirectory(directory: json['directory'] as String?);

Map<String, dynamic> _$CtsListenToAssetDirectoryToJson(
  CtsListenToAssetDirectory instance,
) => <String, dynamic>{'directory': instance.directory};

StcAssetDirectoryStreamUpdate _$StcAssetDirectoryStreamUpdateFromJson(
  Map<String, dynamic> json,
) => StcAssetDirectoryStreamUpdate(
  directory: json['directory'] as String?,
  updated: (json['updated'] as List<dynamic>)
      .map((e) => AssetEntry.fromJson(e as Map<String, dynamic>))
      .toList(),
  removed: (json['removed'] as List<dynamic>).map((e) => e as String).toList(),
);

Map<String, dynamic> _$StcAssetDirectoryStreamUpdateToJson(
  StcAssetDirectoryStreamUpdate instance,
) => <String, dynamic>{
  'directory': instance.directory,
  'updated': instance.updated,
  'removed': instance.removed,
};

PtpAssetBlob _$PtpAssetBlobFromJson(Map<String, dynamic> json) => PtpAssetBlob(
  uuid: json['uuid'] as String,
  offset: (json['offset'] as num).toInt(),
  size: (json['size'] as num).toInt(),
  data: json['data'] as String,
);

Map<String, dynamic> _$PtpAssetBlobToJson(PtpAssetBlob instance) =>
    <String, dynamic>{
      'uuid': instance.uuid,
      'offset': instance.offset,
      'size': instance.size,
      'data': instance.data,
    };
