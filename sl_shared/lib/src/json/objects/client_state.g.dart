// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClientState _$ClientStateFromJson(Map<String, dynamic> json) => ClientState(
  clientId: (json['clientId'] as num).toInt(),
  color: (json['color'] as num).toInt(),
  sceneId: json['sceneId'] as String?,
);

Map<String, dynamic> _$ClientStateToJson(ClientState instance) =>
    <String, dynamic>{
      'clientId': instance.clientId,
      'color': instance.color,
      'sceneId': instance.sceneId,
    };

ClientSceneState _$ClientSceneStateFromJson(Map<String, dynamic> json) =>
    ClientSceneState(
      viewPosition: json['viewPosition'] == null
          ? null
          : ViewPosition.fromJson(json['viewPosition'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ClientSceneStateToJson(ClientSceneState instance) =>
    <String, dynamic>{'viewPosition': instance.viewPosition};

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

CtsSetSceneState _$CtsSetSceneStateFromJson(Map<String, dynamic> json) =>
    CtsSetSceneState(
      sceneId: json['sceneId'] as String?,
      state: json['state'] == null
          ? null
          : ClientSceneState.fromJson(json['state'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CtsSetSceneStateToJson(CtsSetSceneState instance) =>
    <String, dynamic>{'sceneId': instance.sceneId, 'state': instance.state};

StcSetClientSceneStates _$StcSetClientSceneStatesFromJson(
  Map<String, dynamic> json,
) => StcSetClientSceneStates(
  sceneId: json['sceneId'] as String,
  states: (json['states'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(
      int.parse(k),
      ClientSceneState.fromJson(e as Map<String, dynamic>),
    ),
  ),
);

Map<String, dynamic> _$StcSetClientSceneStatesToJson(
  StcSetClientSceneStates instance,
) => <String, dynamic>{
  'sceneId': instance.sceneId,
  'states': instance.states.map((k, e) => MapEntry(k.toString(), e)),
};
