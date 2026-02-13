import 'package:json_annotation/json_annotation.dart';
import 'package:sl_shared/sl_shared.dart';

part 'state_tracking.g.dart';

typedef ClientChangeId = int;
typedef ObjectClass = String;
typedef Delta = Map<String, dynamic>;

@JsonSerializable()
class StateChange {
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
  final Map<ClientChangeId, StateChange> stateChanges;

  CtsStateChanges({
    required this.stateChanges,
  });

  @override
  String get messageClass => '$CtsStateChanges';
  static String get messageClassS => '$CtsStateChanges';

  factory CtsStateChanges.fromJson(Map<String, dynamic> json) => _$CtsStateChangesFromJson(json);
  Map<String, dynamic> toJson() => _$CtsStateChangesToJson(this);
}

@JsonSerializable()
class StcStateChanges extends Message {
  final Map<ClientChangeId, bool> localChangeDecision;
  final List<StateChange> remoteChanges;

  StcStateChanges({
    required this.localChangeDecision,
    required this.remoteChanges,
  });

  @override
  String get messageClass => '$StcStateChanges';
  static String get messageClassS => '$StcStateChanges';

  factory StcStateChanges.fromJson(Map<String, dynamic> json) => _$StcStateChangesFromJson(json);
  Map<String, dynamic> toJson() => _$StcStateChangesToJson(this);
}
