import 'package:json_annotation/json_annotation.dart';
import 'package:sl_shared/sl_shared.dart';

part 'state_tracking.g.dart';

typedef ClientChangeId = int;
typedef ObjectClass = String;
typedef Delta = Map<String, dynamic>;

@JsonSerializable()
class StateChange {
  @JsonKey(includeIfNull: false)
  final ObjectClass? objectClass;
  final UUID objectId;
  final Delta delta;

  StateChange({
    this.objectClass,
    required this.objectId,
    required this.delta,
  });

  factory StateChange.fromJson(Map<String, dynamic> json) => _$StateChangeFromJson(json);
  Map<String, dynamic> toJson() => _$StateChangeToJson(this);
}

@JsonSerializable()
class CtsStateChanges extends Message {
  final UUID sceneId;
  final Map<ClientChangeId, StateChange> stateChanges;

  CtsStateChanges({
    required this.sceneId,
    required this.stateChanges,
  });

  @override
  String get messageClass => '$CtsStateChanges';
  static String get messageClassS => '$CtsStateChanges';

  factory CtsStateChanges.fromJson(Map<String, dynamic> json) => _$CtsStateChangesFromJson(json);
  Map<String, dynamic> toJson() => _$CtsStateChangesToJson(this);
}

@JsonSerializable()
class StcLocalChangeDecisions extends Message {
  final UUID sceneId;
  final Map<ClientChangeId, bool> localChangeDecisions;

  StcLocalChangeDecisions({
    required this.sceneId,
    required this.localChangeDecisions,
  });

  @override
  String get messageClass => '$StcLocalChangeDecisions';
  static String get messageClassS => '$StcLocalChangeDecisions';

  factory StcLocalChangeDecisions.fromJson(Map<String, dynamic> json) => _$StcLocalChangeDecisionsFromJson(json);
  Map<String, dynamic> toJson() => _$StcLocalChangeDecisionsToJson(this);
}

@JsonSerializable()
class StcRemoteChanges extends Message {
  final UUID sceneId;
  final List<StateChange> remoteChanges;
  final ClientChangeId latestAcknowledgedChangeId;

  StcRemoteChanges({
    required this.sceneId,
    required this.remoteChanges,
    required this.latestAcknowledgedChangeId,
  });

  @override
  String get messageClass => '$StcRemoteChanges';
  static String get messageClassS => '$StcRemoteChanges';

  factory StcRemoteChanges.fromJson(Map<String, dynamic> json) => _$StcRemoteChangesFromJson(json);
  Map<String, dynamic> toJson() => _$StcRemoteChangesToJson(this);
}
