// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'state_tracking.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StateChange _$StateChangeFromJson(Map<String, dynamic> json) => StateChange(
  objectClass: json['objectClass'] as String?,
  objectId: json['objectId'] as String,
  delta: json['delta'] as Map<String, dynamic>,
);

Map<String, dynamic> _$StateChangeToJson(StateChange instance) =>
    <String, dynamic>{
      'objectClass': ?instance.objectClass,
      'objectId': instance.objectId,
      'delta': instance.delta,
    };

CtsStateChanges _$CtsStateChangesFromJson(Map<String, dynamic> json) =>
    CtsStateChanges(
      system: $enumDecode(_$StateTrackerSystemEnumMap, json['system']),
      stateChanges: (json['stateChanges'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(
          int.parse(k),
          StateChange.fromJson(e as Map<String, dynamic>),
        ),
      ),
    );

Map<String, dynamic> _$CtsStateChangesToJson(CtsStateChanges instance) =>
    <String, dynamic>{
      'system': _$StateTrackerSystemEnumMap[instance.system]!,
      'stateChanges': instance.stateChanges.map(
        (k, e) => MapEntry(k.toString(), e),
      ),
    };

const _$StateTrackerSystemEnumMap = {
  StateTrackerSystem.scene: 'scene',
  StateTrackerSystem.asset: 'asset',
};

StcLocalChangeDecisions _$StcLocalChangeDecisionsFromJson(
  Map<String, dynamic> json,
) => StcLocalChangeDecisions(
  system: $enumDecode(_$StateTrackerSystemEnumMap, json['system']),
  localChangeDecisions: (json['localChangeDecisions'] as Map<String, dynamic>)
      .map((k, e) => MapEntry(int.parse(k), e as bool)),
);

Map<String, dynamic> _$StcLocalChangeDecisionsToJson(
  StcLocalChangeDecisions instance,
) => <String, dynamic>{
  'system': _$StateTrackerSystemEnumMap[instance.system]!,
  'localChangeDecisions': instance.localChangeDecisions.map(
    (k, e) => MapEntry(k.toString(), e),
  ),
};

StcRemoteChanges _$StcRemoteChangesFromJson(Map<String, dynamic> json) =>
    StcRemoteChanges(
      system: $enumDecode(_$StateTrackerSystemEnumMap, json['system']),
      remoteChanges: (json['remoteChanges'] as List<dynamic>)
          .map((e) => StateChange.fromJson(e as Map<String, dynamic>))
          .toList(),
      latestAcknowledgedChangeId: (json['latestAcknowledgedChangeId'] as num)
          .toInt(),
    );

Map<String, dynamic> _$StcRemoteChangesToJson(StcRemoteChanges instance) =>
    <String, dynamic>{
      'system': _$StateTrackerSystemEnumMap[instance.system]!,
      'remoteChanges': instance.remoteChanges,
      'latestAcknowledgedChangeId': instance.latestAcknowledgedChangeId,
    };
