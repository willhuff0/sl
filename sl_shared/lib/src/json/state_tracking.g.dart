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
      'objectClass': instance.objectClass,
      'objectId': instance.objectId,
      'delta': instance.delta,
    };

CtsStateChanges _$CtsStateChangesFromJson(Map<String, dynamic> json) =>
    CtsStateChanges(
      stateChanges: (json['stateChanges'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(
          int.parse(k),
          StateChange.fromJson(e as Map<String, dynamic>),
        ),
      ),
    );

Map<String, dynamic> _$CtsStateChangesToJson(CtsStateChanges instance) =>
    <String, dynamic>{
      'stateChanges': instance.stateChanges.map(
        (k, e) => MapEntry(k.toString(), e),
      ),
    };

StcStateChanges _$StcStateChangesFromJson(Map<String, dynamic> json) =>
    StcStateChanges(
      localChangeDecision: (json['localChangeDecision'] as Map<String, dynamic>)
          .map((k, e) => MapEntry(int.parse(k), e as bool)),
      remoteChanges: (json['remoteChanges'] as List<dynamic>)
          .map((e) => StateChange.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$StcStateChangesToJson(StcStateChanges instance) =>
    <String, dynamic>{
      'localChangeDecision': instance.localChangeDecision.map(
        (k, e) => MapEntry(k.toString(), e),
      ),
      'remoteChanges': instance.remoteChanges,
    };
