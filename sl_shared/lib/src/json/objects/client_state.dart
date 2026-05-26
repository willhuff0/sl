import 'package:json_annotation/json_annotation.dart';
import 'package:sl_shared/sl_shared.dart';

part 'client_state.g.dart';

@JsonSerializable()
class ClientState {
  final ClientId clientId;
  final String name;
  final int color;
  UUID? sceneId;

  ClientState({required this.clientId, required this.name, required this.color, this.sceneId});

  factory ClientState.fromJson(Map<String, dynamic> json) => _$ClientStateFromJson(json);
  Map<String, dynamic> toJson() => _$ClientStateToJson(this);
}

@JsonSerializable()
class ClientSceneState {
  ViewPosition? viewPosition;

  ClientSceneState({required this.viewPosition});

  factory ClientSceneState.fromJson(Map<String, dynamic> json) => _$ClientSceneStateFromJson(json);
  Map<String, dynamic> toJson() => _$ClientSceneStateToJson(this);
}

@JsonSerializable()
class StcSetGlobalState extends Message {
  final Map<ClientId, ClientState> clients;

  StcSetGlobalState({required this.clients});

  @override
  String get messageClass => 'StcSetGlobalState';
  static String get messageClassS => 'StcSetGlobalState';

  factory StcSetGlobalState.fromJson(Map<String, dynamic> json) => _$StcSetGlobalStateFromJson(json);
  Map<String, dynamic> toJson() => _$StcSetGlobalStateToJson(this);
}

@JsonSerializable()
class CtsSetSceneState extends Message {
  final UUID? sceneId;
  final ClientSceneState? state;

  CtsSetSceneState({required this.sceneId, required this.state});

  @override
  String get messageClass => 'CtsSetSceneState';
  static String get messageClassS => 'CtsSetSceneState';

  factory CtsSetSceneState.fromJson(Map<String, dynamic> json) => _$CtsSetSceneStateFromJson(json);
  Map<String, dynamic> toJson() => _$CtsSetSceneStateToJson(this);
}

@JsonSerializable()
class StcSetClientSceneStates extends Message {
  final UUID sceneId;
  final Map<ClientId, ClientSceneState> states;

  StcSetClientSceneStates({required this.sceneId, required this.states});

  @override
  String get messageClass => 'StcSetClientSceneStates';
  static String get messageClassS => 'StcSetClientSceneStates';

  factory StcSetClientSceneStates.fromJson(Map<String, dynamic> json) => _$StcSetClientSceneStatesFromJson(json);
  Map<String, dynamic> toJson() => _$StcSetClientSceneStatesToJson(this);
}
