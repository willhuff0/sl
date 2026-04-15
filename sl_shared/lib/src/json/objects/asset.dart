import 'package:json_annotation/json_annotation.dart';
import 'package:sl_shared/sl_shared.dart';

part 'asset.g.dart';

const assetBlobChunkSize = 64 * 1024; // 64 KiB
const assetBlobProgressInterval = 4; // chunks
const assetBlobTimeout = Duration(seconds: 30);

enum AssetType {
  directory,
  unsupported,
  propertiesOnly,
  texture,
  mesh,
  model,
  shader,
  nodeTree,
}

@JsonSerializable()
class CtsDeleteAssets extends Message {
  final Set<UUID> uuids;

  CtsDeleteAssets({
    required this.uuids,
  });

  @override
  String get messageClass => '$CtsDeleteAssets';
  static String get messageClassS => '$CtsDeleteAssets';

  factory CtsDeleteAssets.fromJson(Map<String, dynamic> json) => _$CtsDeleteAssetsFromJson(json);

  Map<String, dynamic> toJson() => _$CtsDeleteAssetsToJson(this);
}

@JsonSerializable()
class CtsRequestAssetBlob extends Message {
  final UUID uuid;
  final int offset;

  CtsRequestAssetBlob({
    required this.uuid,
    required this.offset,
  });

  @override
  String get messageClass => '$CtsRequestAssetBlob';
  static String get messageClassS => '$CtsRequestAssetBlob';

  factory CtsRequestAssetBlob.fromJson(Map<String, dynamic> json) => _$CtsRequestAssetBlobFromJson(json);

  Map<String, dynamic> toJson() => _$CtsRequestAssetBlobToJson(this);
}

@JsonSerializable()
class PtpAssetBlobStart extends Message {
  final UUID uuid;
  final int offset;
  final int size;

  PtpAssetBlobStart({
    required this.uuid,
    required this.offset,
    required this.size,
  });

  @override
  String get messageClass => '$PtpAssetBlobStart';
  static String get messageClassS => '$PtpAssetBlobStart';

  factory PtpAssetBlobStart.fromJson(Map<String, dynamic> json) => _$PtpAssetBlobStartFromJson(json);

  Map<String, dynamic> toJson() => _$PtpAssetBlobStartToJson(this);
}

@JsonSerializable()
class PtpAssetBlobEnd extends Message {
  final UUID uuid;
  final int version;

  PtpAssetBlobEnd({
    required this.uuid,
    required this.version,
  });

  @override
  String get messageClass => '$PtpAssetBlobEnd';
  static String get messageClassS => '$PtpAssetBlobEnd';

  factory PtpAssetBlobEnd.fromJson(Map<String, dynamic> json) => _$PtpAssetBlobEndFromJson(json);

  Map<String, dynamic> toJson() => _$PtpAssetBlobEndToJson(this);
}

@JsonSerializable()
class StcAssetBlobProgress extends Message {
  final UUID uuid;
  final int bytesReceived;

  StcAssetBlobProgress({
    required this.uuid,
    required this.bytesReceived,
  });

  @override
  String get messageClass => '$StcAssetBlobProgress';
  static String get messageClassS => '$StcAssetBlobProgress';

  factory StcAssetBlobProgress.fromJson(Map<String, dynamic> json) => _$StcAssetBlobProgressFromJson(json);

  Map<String, dynamic> toJson() => _$StcAssetBlobProgressToJson(this);
}

@JsonSerializable()
class PtpAssetBlobError extends Message {
  final UUID? uuid;
  final String error;

  PtpAssetBlobError({
    required this.uuid,
    required this.error,
  });

  @override
  String get messageClass => '$PtpAssetBlobError';
  static String get messageClassS => '$PtpAssetBlobError';

  factory PtpAssetBlobError.fromJson(Map<String, dynamic> json) => _$PtpAssetBlobErrorFromJson(json);

  Map<String, dynamic> toJson() => _$PtpAssetBlobErrorToJson(this);
}
