// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client_state.dart';

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
