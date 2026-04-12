// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CtsListenToAssetDirectory _$CtsListenToAssetDirectoryFromJson(
  Map<String, dynamic> json,
) => CtsListenToAssetDirectory(directory: json['directory'] as String?);

Map<String, dynamic> _$CtsListenToAssetDirectoryToJson(
  CtsListenToAssetDirectory instance,
) => <String, dynamic>{'directory': instance.directory};

CtsRequestAssetBlob _$CtsRequestAssetBlobFromJson(Map<String, dynamic> json) =>
    CtsRequestAssetBlob(
      uuid: json['uuid'] as String,
      offset: (json['offset'] as num).toInt(),
      length: (json['length'] as num).toInt(),
    );

Map<String, dynamic> _$CtsRequestAssetBlobToJson(
  CtsRequestAssetBlob instance,
) => <String, dynamic>{
  'uuid': instance.uuid,
  'offset': instance.offset,
  'length': instance.length,
};

PtpAssetBlobStart _$PtpAssetBlobStartFromJson(Map<String, dynamic> json) =>
    PtpAssetBlobStart(
      uuid: json['uuid'] as String,
      offset: (json['offset'] as num).toInt(),
      length: (json['length'] as num).toInt(),
      size: (json['size'] as num).toInt(),
    );

Map<String, dynamic> _$PtpAssetBlobStartToJson(PtpAssetBlobStart instance) =>
    <String, dynamic>{
      'uuid': instance.uuid,
      'offset': instance.offset,
      'length': instance.length,
      'size': instance.size,
    };

PtpAssetBlobEnd _$PtpAssetBlobEndFromJson(Map<String, dynamic> json) =>
    PtpAssetBlobEnd(uuid: json['uuid'] as String);

Map<String, dynamic> _$PtpAssetBlobEndToJson(PtpAssetBlobEnd instance) =>
    <String, dynamic>{'uuid': instance.uuid};

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
      error: $enumDecode(_$AssetBlobErrorEnumMap, json['error']),
    );

Map<String, dynamic> _$PtpAssetBlobErrorToJson(PtpAssetBlobError instance) =>
    <String, dynamic>{
      'uuid': instance.uuid,
      'error': _$AssetBlobErrorEnumMap[instance.error]!,
    };

const _$AssetBlobErrorEnumMap = {
  AssetBlobError.assetDoesNotExist: 'assetDoesNotExist',
  AssetBlobError.assetBlobLocked: 'assetBlobLocked',
  AssetBlobError.operationNotStarted: 'operationNotStarted',
  AssetBlobError.simultaneousUploadsFromSingleClientNotAllowed:
      'simultaneousUploadsFromSingleClientNotAllowed',
  AssetBlobError.operationTimedOut: 'operationTimedOut',
};
