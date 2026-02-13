// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'objects.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClientState _$ClientStateFromJson(Map<String, dynamic> json) => ClientState(
  clientId: (json['clientId'] as num).toInt(),
  scopeId: json['scopeId'] as String,
  color: (json['color'] as num).toInt(),
);

Map<String, dynamic> _$ClientStateToJson(ClientState instance) =>
    <String, dynamic>{
      'clientId': instance.clientId,
      'scopeId': instance.scopeId,
      'color': instance.color,
    };

CursorPosition _$CursorPositionFromJson(Map<String, dynamic> json) =>
    CursorPosition(
      panel: $enumDecode(_$PanelTypeEnumMap, json['panel']),
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
    );

Map<String, dynamic> _$CursorPositionToJson(CursorPosition instance) =>
    <String, dynamic>{
      'panel': _$PanelTypeEnumMap[instance.panel]!,
      'x': instance.x,
      'y': instance.y,
    };

const _$PanelTypeEnumMap = {
  PanelType.asset: 'asset',
  PanelType.console: 'console',
  PanelType.engine: 'engine',
  PanelType.nodeGraph: 'nodeGraph',
  PanelType.properties: 'properties',
};
