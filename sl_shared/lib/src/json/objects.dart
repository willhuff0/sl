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
  final UUID scopeId;
  final int color;

  ClientState({required this.clientId, required this.scopeId, required this.color});

  factory ClientState.fromJson(Map<String, dynamic> json) => _$ClientStateFromJson(json);
  Map<String, dynamic> toJson() => _$ClientStateToJson(this);
}

enum PanelType {
  asset,
  console,
  engine,
  nodeGraph,
  properties,
}

@JsonSerializable()
class CursorPosition {
  final PanelType panel;
  final double x;
  final double y;

  CursorPosition({required this.panel, required this.x, required this.y});

  factory CursorPosition.fromJson(Map<String, dynamic> json) => _$CursorPositionFromJson(json);
  Map<String, dynamic> toJson() => _$CursorPositionToJson(this);
}
