// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CtsDeleteAssets _$CtsDeleteAssetsFromJson(Map<String, dynamic> json) =>
    CtsDeleteAssets(
      uuids: (json['uuids'] as List<dynamic>).map((e) => e as String).toSet(),
    );

Map<String, dynamic> _$CtsDeleteAssetsToJson(CtsDeleteAssets instance) =>
    <String, dynamic>{'uuids': instance.uuids.toList()};

CtsRequestAssetBlob _$CtsRequestAssetBlobFromJson(Map<String, dynamic> json) =>
    CtsRequestAssetBlob(
      uuid: json['uuid'] as String,
      offset: (json['offset'] as num).toInt(),
    );

Map<String, dynamic> _$CtsRequestAssetBlobToJson(
  CtsRequestAssetBlob instance,
) => <String, dynamic>{'uuid': instance.uuid, 'offset': instance.offset};

PtpAssetBlobStart _$PtpAssetBlobStartFromJson(Map<String, dynamic> json) =>
    PtpAssetBlobStart(
      uuid: json['uuid'] as String,
      offset: (json['offset'] as num).toInt(),
      size: (json['size'] as num).toInt(),
    );

Map<String, dynamic> _$PtpAssetBlobStartToJson(PtpAssetBlobStart instance) =>
    <String, dynamic>{
      'uuid': instance.uuid,
      'offset': instance.offset,
      'size': instance.size,
    };

PtpAssetBlobEnd _$PtpAssetBlobEndFromJson(Map<String, dynamic> json) =>
    PtpAssetBlobEnd(
      uuid: json['uuid'] as String,
      version: (json['version'] as num).toInt(),
    );

Map<String, dynamic> _$PtpAssetBlobEndToJson(PtpAssetBlobEnd instance) =>
    <String, dynamic>{'uuid': instance.uuid, 'version': instance.version};

StcAssetBlobProgress _$StcAssetBlobProgressFromJson(
  Map<String, dynamic> json,
) => StcAssetBlobProgress(
  uuid: json['uuid'] as String,
  bytesReceived: (json['bytesReceived'] as num).toInt(),
);

Map<String, dynamic> _$StcAssetBlobProgressToJson(
  StcAssetBlobProgress instance,
) => <String, dynamic>{
  'uuid': instance.uuid,
  'bytesReceived': instance.bytesReceived,
};

PtpAssetBlobError _$PtpAssetBlobErrorFromJson(Map<String, dynamic> json) =>
    PtpAssetBlobError(
      uuid: json['uuid'] as String?,
      error: json['error'] as String,
    );

Map<String, dynamic> _$PtpAssetBlobErrorToJson(PtpAssetBlobError instance) =>
    <String, dynamic>{'uuid': instance.uuid, 'error': instance.error};
