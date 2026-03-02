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

ViewPosition _$ViewPositionFromJson(Map<String, dynamic> json) => ViewPosition(
  panel: $enumDecode(_$PanelTypeEnumMap, json['panel']),
  cursorX: (json['cursorX'] as num).toDouble(),
  cursorY: (json['cursorY'] as num).toDouble(),
  enginePosition: _$recordConvert(
    json['enginePosition'],
    ($jsonValue) => (
      ($jsonValue[r'$1'] as num).toDouble(),
      ($jsonValue[r'$2'] as num).toDouble(),
      ($jsonValue[r'$3'] as num).toDouble(),
    ),
  ),
  engineOrientation: _$recordConvert(
    json['engineOrientation'],
    ($jsonValue) => (
      ($jsonValue[r'$1'] as num).toDouble(),
      ($jsonValue[r'$2'] as num).toDouble(),
      ($jsonValue[r'$3'] as num).toDouble(),
      ($jsonValue[r'$4'] as num).toDouble(),
    ),
  ),
);

Map<String, dynamic> _$ViewPositionToJson(ViewPosition instance) =>
    <String, dynamic>{
      'panel': _$PanelTypeEnumMap[instance.panel]!,
      'cursorX': instance.cursorX,
      'cursorY': instance.cursorY,
      'enginePosition': <String, dynamic>{
        r'$1': instance.enginePosition.$1,
        r'$2': instance.enginePosition.$2,
        r'$3': instance.enginePosition.$3,
      },
      'engineOrientation': <String, dynamic>{
        r'$1': instance.engineOrientation.$1,
        r'$2': instance.engineOrientation.$2,
        r'$3': instance.engineOrientation.$3,
        r'$4': instance.engineOrientation.$4,
      },
    };

const _$PanelTypeEnumMap = {
  PanelType.asset: 'asset',
  PanelType.console: 'console',
  PanelType.engine: 'engine',
  PanelType.nodeGraph: 'nodeGraph',
  PanelType.properties: 'properties',
};

$Rec _$recordConvert<$Rec>(Object? value, $Rec Function(Map) convert) =>
    convert(value as Map<String, dynamic>);
