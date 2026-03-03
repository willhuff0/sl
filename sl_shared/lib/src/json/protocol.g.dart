// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'protocol.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StcSetSelf _$StcSetSelfFromJson(Map<String, dynamic> json) =>
    StcSetSelf(clientId: (json['clientId'] as num).toInt());

Map<String, dynamic> _$StcSetSelfToJson(StcSetSelf instance) =>
    <String, dynamic>{'clientId': instance.clientId};

StcSetClientGlobalStates _$StcSetClientGlobalStatesFromJson(
  Map<String, dynamic> json,
) => StcSetClientGlobalStates(
  states: (json['states'] as Map<String, dynamic>).map(
    (k, e) =>
        MapEntry(int.parse(k), ClientState.fromJson(e as Map<String, dynamic>)),
  ),
);

Map<String, dynamic> _$StcSetClientGlobalStatesToJson(
  StcSetClientGlobalStates instance,
) => <String, dynamic>{
  'states': instance.states.map((k, e) => MapEntry(k.toString(), e)),
};

CtsSetScopeState _$CtsSetScopeStateFromJson(Map<String, dynamic> json) =>
    CtsSetScopeState(
      scopeId: json['scopeId'] as String?,
      state: json['state'] == null
          ? null
          : ClientScopeState.fromJson(json['state'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CtsSetScopeStateToJson(CtsSetScopeState instance) =>
    <String, dynamic>{'scopeId': instance.scopeId, 'state': instance.state};

StcSetClientScopeStates _$StcSetClientScopeStatesFromJson(
  Map<String, dynamic> json,
) => StcSetClientScopeStates(
  scopeId: json['scopeId'] as String,
  states: (json['states'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(
      int.parse(k),
      ClientScopeState.fromJson(e as Map<String, dynamic>),
    ),
  ),
);

Map<String, dynamic> _$StcSetClientScopeStatesToJson(
  StcSetClientScopeStates instance,
) => <String, dynamic>{
  'scopeId': instance.scopeId,
  'states': instance.states.map((k, e) => MapEntry(k.toString(), e)),
};
