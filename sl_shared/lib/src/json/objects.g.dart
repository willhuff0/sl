// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'objects.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClientState _$ClientStateFromJson(Map<String, dynamic> json) => ClientState(
  clientId: (json['clientId'] as num).toInt(),
  color: (json['color'] as num).toInt(),
  scopeId: json['scopeId'] as String?,
);

Map<String, dynamic> _$ClientStateToJson(ClientState instance) =>
    <String, dynamic>{
      'clientId': instance.clientId,
      'color': instance.color,
      'scopeId': instance.scopeId,
    };

ClientScopeState _$ClientScopeStateFromJson(Map<String, dynamic> json) =>
    ClientScopeState(
      viewPosition: json['viewPosition'] == null
          ? null
          : ViewPosition.fromJson(json['viewPosition'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ClientScopeStateToJson(ClientScopeState instance) =>
    <String, dynamic>{'viewPosition': instance.viewPosition};

ViewPosition _$ViewPositionFromJson(Map<String, dynamic> json) => ViewPosition(
  position: _$recordConvert(
    json['position'],
    ($jsonValue) => (
      ($jsonValue[r'$1'] as num).toDouble(),
      ($jsonValue[r'$2'] as num).toDouble(),
      ($jsonValue[r'$3'] as num).toDouble(),
    ),
  ),
  orientation: _$recordConvert(
    json['orientation'],
    ($jsonValue) => (
      ($jsonValue[r'$1'] as num).toDouble(),
      ($jsonValue[r'$2'] as num).toDouble(),
      ($jsonValue[r'$3'] as num).toDouble(),
      ($jsonValue[r'$4'] as num).toDouble(),
    ),
  ),
  fov: (json['fov'] as num).toDouble(),
  cursor: _$recordConvert(
    json['cursor'],
    ($jsonValue) => (
      ($jsonValue[r'$1'] as num).toDouble(),
      ($jsonValue[r'$2'] as num).toDouble(),
    ),
  ),
  selection: (json['selection'] as List<dynamic>)
      .map((e) => e as String)
      .toSet(),
);

Map<String, dynamic> _$ViewPositionToJson(ViewPosition instance) =>
    <String, dynamic>{
      'position': <String, dynamic>{
        r'$1': instance.position.$1,
        r'$2': instance.position.$2,
        r'$3': instance.position.$3,
      },
      'orientation': <String, dynamic>{
        r'$1': instance.orientation.$1,
        r'$2': instance.orientation.$2,
        r'$3': instance.orientation.$3,
        r'$4': instance.orientation.$4,
      },
      'fov': instance.fov,
      'cursor': <String, dynamic>{
        r'$1': instance.cursor.$1,
        r'$2': instance.cursor.$2,
      },
      'selection': instance.selection.toList(),
    };

$Rec _$recordConvert<$Rec>(Object? value, $Rec Function(Map) convert) =>
    convert(value as Map<String, dynamic>);
