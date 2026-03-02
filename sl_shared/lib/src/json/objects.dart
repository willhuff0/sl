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
class ViewPosition {
  final PanelType panel;
  final double cursorX;
  final double cursorY;
  final (double, double, double) enginePosition;
  final (double, double, double, double) engineOrientation;

  ViewPosition({
    required this.panel,
    required this.cursorX,
    required this.cursorY,
    required this.enginePosition,
    required this.engineOrientation,
  });

  factory ViewPosition.fromJson(Map<String, dynamic> json) => _$ViewPositionFromJson(json);
  Map<String, dynamic> toJson() => _$ViewPositionToJson(this);
}
