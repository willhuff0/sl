import 'package:json_annotation/json_annotation.dart';
import 'package:sl_shared/sl_shared.dart';

part 'state_tracking.g.dart';

typedef ClientChangeId = int;
typedef ServerSeq = int;
typedef ObjectClass = String;
typedef Delta = Map<String, dynamic>;

/// A client-submitted change. `objectClass` is non-null only when the change creates the object.
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

/// A change the server has applied to its authoritative state, stamped with a total-order
/// sequence. `originChangeId` is set only on the copy sent back to the change's author, letting
/// that client move the change from its pending queue into its confirmed layer.
@JsonSerializable()
class AppliedChange {
  final ServerSeq serverSeq;

  @JsonKey(includeIfNull: false)
  final ClientChangeId? originChangeId;

  @JsonKey(includeIfNull: false)
  final ObjectClass? objectClass;

  final UUID objectId;
  final Delta delta;

  AppliedChange({
    required this.serverSeq,
    this.originChangeId,
    this.objectClass,
    required this.objectId,
    required this.delta,
  });

  factory AppliedChange.fromJson(Map<String, dynamic> json) => _$AppliedChangeFromJson(json);
  Map<String, dynamic> toJson() => _$AppliedChangeToJson(this);
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
  String get messageClass => 'CtsStateChanges';
  static String get messageClassS => 'CtsStateChanges';

  factory CtsStateChanges.fromJson(Map<String, dynamic> json) => _$CtsStateChangesFromJson(json);
  Map<String, dynamic> toJson() => _$CtsStateChangesToJson(this);
}

/// Authoritative, sequenced log of applied changes. Sent to every interested client (including
/// the author). `changes` are contiguous in [ServerSeq] starting at [firstSeq]; a client that
/// sees a gap requests a resync. `rejectedLocalChanges` (author-only) lists the author's change
/// ids the server declined — they never appear in the log, so they are simply dropped.
@JsonSerializable()
class StcStateLog extends Message {
  final UUID sceneId;

  /// [ServerSeq] of `changes.first`. `-1` when `changes` is empty (rejections-only message).
  final ServerSeq firstSeq;
  final List<AppliedChange> changes;
  final List<ClientChangeId> rejectedLocalChanges;

  StcStateLog({
    required this.sceneId,
    required this.firstSeq,
    required this.changes,
    this.rejectedLocalChanges = const [],
  });

  @override
  String get messageClass => 'StcStateLog';
  static String get messageClassS => 'StcStateLog';

  factory StcStateLog.fromJson(Map<String, dynamic> json) => _$StcStateLogFromJson(json);
  Map<String, dynamic> toJson() => _$StcStateLogToJson(this);
}

/// Full authoritative snapshot, sent on scene join or in response to [CtsRequestResync]. The
/// client wipes its confirmed layer, loads these objects as confirmed at [baseServerSeq], keeps
/// its un-acknowledged pending changes, and recomputes.
@JsonSerializable()
class StcStateSnapshot extends Message {
  final UUID sceneId;
  final ServerSeq baseServerSeq;
  final List<StateChange> objects;

  StcStateSnapshot({
    required this.sceneId,
    required this.baseServerSeq,
    required this.objects,
  });

  @override
  String get messageClass => 'StcStateSnapshot';
  static String get messageClassS => 'StcStateSnapshot';

  factory StcStateSnapshot.fromJson(Map<String, dynamic> json) => _$StcStateSnapshotFromJson(json);
  Map<String, dynamic> toJson() => _$StcStateSnapshotToJson(this);
}

/// Sent by a client that has detected a desync (sequence gap or a broken invariant) to request a
/// fresh authoritative snapshot.
@JsonSerializable()
class CtsRequestResync extends Message {
  final UUID sceneId;

  CtsRequestResync({required this.sceneId});

  @override
  String get messageClass => 'CtsRequestResync';
  static String get messageClassS => 'CtsRequestResync';

  factory CtsRequestResync.fromJson(Map<String, dynamic> json) => _$CtsRequestResyncFromJson(json);
  Map<String, dynamic> toJson() => _$CtsRequestResyncToJson(this);
}
