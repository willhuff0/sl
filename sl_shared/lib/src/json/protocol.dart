import 'package:json_annotation/json_annotation.dart';
import 'package:sl_shared/sl_shared.dart';

part 'protocol.g.dart';

typedef MessageFactory = Message Function(Map<String, dynamic> json);
final Map<String, MessageFactory> _factories = {
  StcSetSelf.messageClassS: StcSetSelf.fromJson,
  StcSetClients.messageClassS: StcSetClients.fromJson,
  CtsSetCursorPosition.messageClassS: CtsSetCursorPosition.fromJson,
  StcSetCursorPositions.messageClassS: StcSetCursorPositions.fromJson,
};

class MessageAndHeader {
  // final int acknowledgementTimestamp;
  final String messageClass;
  final dynamic messageInstance;

  MessageAndHeader({
    // required this.acknowledgementTimestamp,
    required this.messageClass,
    required this.messageInstance,
  });

  factory MessageAndHeader.fromJson(Map<String, dynamic> json) {
    final class_ = json['class'] as String;
    return MessageAndHeader(
      // acknowledgementTimestamp: (json['ack'] as num).toInt(),
      messageClass: class_,
      messageInstance: _factories[class_]!(json['message'] as Map<String, dynamic>),
    );
  }
  Map<String, dynamic> toJson() => {
    // 'ack': acknowledgementTimestamp,
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
class CtsSetCursorPosition extends Message {
  final UUID scopeId;
  final CursorPosition? value;

  CtsSetCursorPosition({required this.scopeId, required this.value});

  @override
  String get messageClass => '$CtsSetCursorPosition';
  static String get messageClassS => '$CtsSetCursorPosition';

  factory CtsSetCursorPosition.fromJson(Map<String, dynamic> json) => _$CtsSetCursorPositionFromJson(json);
  Map<String, dynamic> toJson() => _$CtsSetCursorPositionToJson(this);
}

@JsonSerializable()
class StcSetCursorPositions extends Message {
  final UUID scopeId;
  final Map<ClientId, CursorPosition> values;

  StcSetCursorPositions({required this.scopeId, required this.values});

  @override
  String get messageClass => '$StcSetCursorPositions';
  static String get messageClassS => '$StcSetCursorPositions';

  factory StcSetCursorPositions.fromJson(Map<String, dynamic> json) => _$StcSetCursorPositionsFromJson(json);
  Map<String, dynamic> toJson() => _$StcSetCursorPositionsToJson(this);
}
