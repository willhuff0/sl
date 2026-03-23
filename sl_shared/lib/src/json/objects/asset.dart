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
class AssetEntry {
  final UUID uuid;
  final String name;
  final AssetType type;
  final List<AssetEntry> subAssets;

  AssetEntry({
    required this.uuid,
    required this.name,
    required this.type,
    required this.subAssets,
  });

  factory AssetEntry.fromJson(Map<String, dynamic> json) => _$AssetEntryFromJson(json);

  Map<String, dynamic> toJson() => _$AssetEntryToJson(this);
}
