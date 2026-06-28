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

AppliedChange _$AppliedChangeFromJson(Map<String, dynamic> json) =>
    AppliedChange(
      serverSeq: (json['serverSeq'] as num).toInt(),
      originChangeId: (json['originChangeId'] as num?)?.toInt(),
      objectClass: json['objectClass'] as String?,
      objectId: json['objectId'] as String,
      delta: json['delta'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$AppliedChangeToJson(AppliedChange instance) =>
    <String, dynamic>{
      'serverSeq': instance.serverSeq,
      'originChangeId': ?instance.originChangeId,
      'objectClass': ?instance.objectClass,
      'objectId': instance.objectId,
      'delta': instance.delta,
    };

CtsStateChanges _$CtsStateChangesFromJson(Map<String, dynamic> json) =>
    CtsStateChanges(
      sceneId: json['sceneId'] as String,
      stateChanges: (json['stateChanges'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(
          int.parse(k),
          StateChange.fromJson(e as Map<String, dynamic>),
        ),
      ),
    );

Map<String, dynamic> _$CtsStateChangesToJson(CtsStateChanges instance) =>
    <String, dynamic>{
      'sceneId': instance.sceneId,
      'stateChanges': instance.stateChanges.map(
        (k, e) => MapEntry(k.toString(), e.toJson()),
      ),
    };

StcStateLog _$StcStateLogFromJson(Map<String, dynamic> json) => StcStateLog(
  sceneId: json['sceneId'] as String,
  firstSeq: (json['firstSeq'] as num).toInt(),
  changes: (json['changes'] as List<dynamic>)
      .map((e) => AppliedChange.fromJson(e as Map<String, dynamic>))
      .toList(),
  rejectedLocalChanges:
      (json['rejectedLocalChanges'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      const [],
);

Map<String, dynamic> _$StcStateLogToJson(StcStateLog instance) =>
    <String, dynamic>{
      'sceneId': instance.sceneId,
      'firstSeq': instance.firstSeq,
      'changes': instance.changes.map((e) => e.toJson()).toList(),
      'rejectedLocalChanges': instance.rejectedLocalChanges,
    };

StcStateSnapshot _$StcStateSnapshotFromJson(Map<String, dynamic> json) =>
    StcStateSnapshot(
      sceneId: json['sceneId'] as String,
      baseServerSeq: (json['baseServerSeq'] as num).toInt(),
      objects: (json['objects'] as List<dynamic>)
          .map((e) => StateChange.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$StcStateSnapshotToJson(StcStateSnapshot instance) =>
    <String, dynamic>{
      'sceneId': instance.sceneId,
      'baseServerSeq': instance.baseServerSeq,
      'objects': instance.objects.map((e) => e.toJson()).toList(),
    };

CtsRequestResync _$CtsRequestResyncFromJson(Map<String, dynamic> json) =>
    CtsRequestResync(sceneId: json['sceneId'] as String);

Map<String, dynamic> _$CtsRequestResyncToJson(CtsRequestResync instance) =>
    <String, dynamic>{'sceneId': instance.sceneId};
