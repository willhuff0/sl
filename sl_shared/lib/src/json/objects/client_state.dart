import 'package:json_annotation/json_annotation.dart';
import 'package:sl_shared/sl_shared.dart';

part 'client_state.g.dart';

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
