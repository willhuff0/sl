// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'protocol.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StcSetSelf _$StcSetSelfFromJson(Map<String, dynamic> json) =>
    StcSetSelf(clientId: (json['clientId'] as num).toInt());

Map<String, dynamic> _$StcSetSelfToJson(StcSetSelf instance) =>
    <String, dynamic>{'clientId': instance.clientId};

StcSetClients _$StcSetClientsFromJson(Map<String, dynamic> json) =>
    StcSetClients(
      states: (json['states'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(
          int.parse(k),
          ClientState.fromJson(e as Map<String, dynamic>),
        ),
      ),
    );

Map<String, dynamic> _$StcSetClientsToJson(StcSetClients instance) =>
    <String, dynamic>{
      'states': instance.states.map((k, e) => MapEntry(k.toString(), e)),
    };

CtsSetViewPosition _$CtsSetViewPositionFromJson(Map<String, dynamic> json) =>
    CtsSetViewPosition(
      scopeId: json['scopeId'] as String,
      value: json['value'] == null
          ? null
          : ViewPosition.fromJson(json['value'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CtsSetViewPositionToJson(CtsSetViewPosition instance) =>
    <String, dynamic>{'scopeId': instance.scopeId, 'value': instance.value};

StcSetViewPositions _$StcSetViewPositionsFromJson(Map<String, dynamic> json) =>
    StcSetViewPositions(
      scopeId: json['scopeId'] as String,
      values: (json['values'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(
          int.parse(k),
          ViewPosition.fromJson(e as Map<String, dynamic>),
        ),
      ),
    );

Map<String, dynamic> _$StcSetViewPositionsToJson(
  StcSetViewPositions instance,
) => <String, dynamic>{
  'scopeId': instance.scopeId,
  'values': instance.values.map((k, e) => MapEntry(k.toString(), e)),
};
