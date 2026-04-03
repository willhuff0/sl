import 'package:json_annotation/json_annotation.dart';
import 'package:sl_shared/sl_shared.dart';

part 'asset.g.dart';

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
class AssetCreateInfo {
  final UUID uuid;
  final UUID? parent;
  final String name;
  final AssetType type;

  AssetCreateInfo({
    required this.uuid,
    required this.parent,
    required this.name,
    required this.type,
  });

  factory AssetCreateInfo.fromJson(Map<String, dynamic> json) => _$AssetCreateInfoFromJson(json);

  Map<String, dynamic> toJson() => _$AssetCreateInfoToJson(this);

  bool validate() {
    // TODO
    return true;
  }
}

@JsonSerializable()
class AssetEntry {
  final UUID uuid;
  final String name;
  final AssetType type;
  final List<AssetEntry> subAssets;
  final int? blobSize;

  AssetEntry({
    required this.uuid,
    required this.name,
    required this.type,
    required this.subAssets,
    this.blobSize,
  });

  factory AssetEntry.fromJson(Map<String, dynamic> json) => _$AssetEntryFromJson(json);

  Map<String, dynamic> toJson() => _$AssetEntryToJson(this);
}

@JsonSerializable()
class CtsCreateAssets extends Message {
  final List<AssetCreateInfo> createInfos;

  CtsCreateAssets({
    required this.createInfos,
  });

  @override
  String get messageClass => '$CtsCreateAssets';
  static String get messageClassS => '$CtsCreateAssets';

  factory CtsCreateAssets.fromJson(Map<String, dynamic> json) => _$CtsCreateAssetsFromJson(json);

  Map<String, dynamic> toJson() => _$CtsCreateAssetsToJson(this);
}

@JsonSerializable()
class CtsDeleteAssets extends Message {
  final List<UUID> uuids;

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
class CtsListenToAssetDirectory extends Message {
  final UUID? directory;

  CtsListenToAssetDirectory({required this.directory});

  @override
  String get messageClass => '$CtsListenToAssetDirectory';
  static String get messageClassS => '$CtsListenToAssetDirectory';

  factory CtsListenToAssetDirectory.fromJson(Map<String, dynamic> json) => _$CtsListenToAssetDirectoryFromJson(json);

  Map<String, dynamic> toJson() => _$CtsListenToAssetDirectoryToJson(this);
}

@JsonSerializable()
class StcAssetDirectoryStreamUpdate extends Message {
  final UUID? directory;
  final List<AssetEntry> updated;
  final List<UUID> removed;

  StcAssetDirectoryStreamUpdate({required this.directory, required this.updated, required this.removed});

  @override
  String get messageClass => '$StcAssetDirectoryStreamUpdate';
  static String get messageClassS => '$StcAssetDirectoryStreamUpdate';

  factory StcAssetDirectoryStreamUpdate.fromJson(Map<String, dynamic> json) =>
      _$StcAssetDirectoryStreamUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$StcAssetDirectoryStreamUpdateToJson(this);
}

@JsonSerializable()
class PtpAssetBlob extends Message {
  final UUID uuid;
  final int offset;
  final int size;
  final String data;

  PtpAssetBlob({
    required this.uuid,
    required this.offset,
    required this.size,
    required this.data,
  });

  @override
  String get messageClass => '$PtpAssetBlob';
  static String get messageClassS => '$PtpAssetBlob';

  factory PtpAssetBlob.fromJson(Map<String, dynamic> json) => _$PtpAssetBlobFromJson(json);

  Map<String, dynamic> toJson() => _$PtpAssetBlobToJson(this);
}
