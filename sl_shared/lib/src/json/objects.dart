import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

export 'state_tracking.dart';

part 'objects.g.dart';

typedef ClientId = int;
typedef UUID = String;

UUID generateUuid() {
  return Uuid().v4();
}

@JsonSerializable()
class ClientState {
  final ClientId clientId;
  final int color;
  UUID? scopeId;

  ClientState({required this.clientId, required this.color, this.scopeId});

  factory ClientState.fromJson(Map<String, dynamic> json) => _$ClientStateFromJson(json);
  Map<String, dynamic> toJson() => _$ClientStateToJson(this);
}

@JsonSerializable()
class ClientScopeState {
  ViewPosition? viewPosition;

  ClientScopeState({required this.viewPosition});

  factory ClientScopeState.fromJson(Map<String, dynamic> json) => _$ClientScopeStateFromJson(json);
  Map<String, dynamic> toJson() => _$ClientScopeStateToJson(this);
}

@JsonSerializable()
class ViewPosition {
  final (double, double, double) position;
  final (double, double, double, double) orientation;
  final double fov;
  final (double, double) cursor;
  final Set<UUID> selection;

  ViewPosition({
    required this.position,
    required this.orientation,
    required this.fov,
    required this.cursor,
    required this.selection,
  });

  factory ViewPosition.fromJson(Map<String, dynamic> json) => _$ViewPositionFromJson(json);
  Map<String, dynamic> toJson() => _$ViewPositionToJson(this);
}
