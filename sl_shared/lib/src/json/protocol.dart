import 'package:json_annotation/json_annotation.dart';
import 'package:sl_shared/sl_shared.dart';

part 'protocol.g.dart';

typedef MessageFactory = Message Function(Map<String, dynamic> json);
final Map<String, MessageFactory> _factories = {
  StcSetSelf.messageClassS: StcSetSelf.fromJson,
  StcSetClientGlobalStates.messageClassS: StcSetClientGlobalStates.fromJson,
  CtsSetScopeState.messageClassS: CtsSetScopeState.fromJson,
  StcSetClientScopeStates.messageClassS: StcSetClientScopeStates.fromJson,
  StcStateChanges.messageClassS: StcStateChanges.fromJson,
  CtsStateChanges.messageClassS: CtsStateChanges.fromJson,
};

class MessageAndHeader {
  final String messageClass;
  final dynamic messageInstance;

  MessageAndHeader({
    required this.messageClass,
    required this.messageInstance,
  });

  factory MessageAndHeader.fromJson(Map<String, dynamic> json) {
    final class_ = json['class'] as String;
    return MessageAndHeader(
      messageClass: class_,
      messageInstance: _factories[class_]!(json['message'] as Map<String, dynamic>),
    );
  }
  Map<String, dynamic> toJson() => {
    'class': messageClass,
    'message': messageInstance,
  };
}

abstract class Message {
  String get messageClass;
}

@JsonSerializable()
class StcSetSelf extends Message {
  final ClientId clientId;

  StcSetSelf({required this.clientId});

  @override
  String get messageClass => '$StcSetSelf';
  static String get messageClassS => '$StcSetSelf';

  factory StcSetSelf.fromJson(Map<String, dynamic> json) => _$StcSetSelfFromJson(json);
  Map<String, dynamic> toJson() => _$StcSetSelfToJson(this);
}

@JsonSerializable()
class StcSetClientGlobalStates extends Message {
  final Map<ClientId, ClientState> states;

  StcSetClientGlobalStates({required this.states});

  @override
  String get messageClass => '$StcSetClientGlobalStates';
  static String get messageClassS => '$StcSetClientGlobalStates';

  factory StcSetClientGlobalStates.fromJson(Map<String, dynamic> json) => _$StcSetClientGlobalStatesFromJson(json);
  Map<String, dynamic> toJson() => _$StcSetClientGlobalStatesToJson(this);
}

@JsonSerializable()
class CtsSetScopeState extends Message {
  final UUID? scopeId;
  final ClientScopeState? state;

  CtsSetScopeState({required this.scopeId, required this.state});

  @override
  String get messageClass => '$CtsSetScopeState';
  static String get messageClassS => '$CtsSetScopeState';

  factory CtsSetScopeState.fromJson(Map<String, dynamic> json) => _$CtsSetScopeStateFromJson(json);
  Map<String, dynamic> toJson() => _$CtsSetScopeStateToJson(this);
}

@JsonSerializable()
class StcSetClientScopeStates extends Message {
  final UUID scopeId;
  final Map<ClientId, ClientScopeState> states;

  StcSetClientScopeStates({required this.scopeId, required this.states});

  @override
  String get messageClass => '$StcSetClientScopeStates';
  static String get messageClassS => '$StcSetClientScopeStates';

  factory StcSetClientScopeStates.fromJson(Map<String, dynamic> json) => _$StcSetClientScopeStatesFromJson(json);
  Map<String, dynamic> toJson() => _$StcSetClientScopeStatesToJson(this);
}
