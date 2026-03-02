import 'package:json_annotation/json_annotation.dart';
import 'package:sl_shared/sl_shared.dart';

part 'protocol.g.dart';

typedef MessageFactory = Message Function(Map<String, dynamic> json);
final Map<String, MessageFactory> _factories = {
  StcSetSelf.messageClassS: StcSetSelf.fromJson,
  StcSetClients.messageClassS: StcSetClients.fromJson,
  CtsSetViewPosition.messageClassS: CtsSetViewPosition.fromJson,
  StcSetViewPositions.messageClassS: StcSetViewPositions.fromJson,
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
class StcSetClients extends Message {
  final Map<ClientId, ClientState> states;

  StcSetClients({required this.states});

  @override
  String get messageClass => '$StcSetClients';
  static String get messageClassS => '$StcSetClients';

  factory StcSetClients.fromJson(Map<String, dynamic> json) => _$StcSetClientsFromJson(json);
  Map<String, dynamic> toJson() => _$StcSetClientsToJson(this);
}

@JsonSerializable()
class CtsSetViewPosition extends Message {
  final UUID scopeId;
  final ViewPosition? value;

  CtsSetViewPosition({required this.scopeId, required this.value});

  @override
  String get messageClass => '$CtsSetViewPosition';
  static String get messageClassS => '$CtsSetViewPosition';

  factory CtsSetViewPosition.fromJson(Map<String, dynamic> json) => _$CtsSetViewPositionFromJson(json);
  Map<String, dynamic> toJson() => _$CtsSetViewPositionToJson(this);
}

@JsonSerializable()
class StcSetViewPositions extends Message {
  final UUID scopeId;
  final Map<ClientId, ViewPosition> values;

  StcSetViewPositions({required this.scopeId, required this.values});

  @override
  String get messageClass => '$StcSetViewPositions';
  static String get messageClassS => '$StcSetViewPositions';

  factory StcSetViewPositions.fromJson(Map<String, dynamic> json) => _$StcSetViewPositionsFromJson(json);
  Map<String, dynamic> toJson() => _$StcSetViewPositionsToJson(this);
}
