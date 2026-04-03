import 'package:json_annotation/json_annotation.dart';
import 'package:sl_shared/sl_shared.dart';

part 'protocol.g.dart';

typedef MessageFactory = Message Function(Map<String, dynamic> json);
final Map<String, MessageFactory> _factories = {
  StcSetSelf.messageClassS: StcSetSelf.fromJson,
  StcSetClientGlobalStates.messageClassS: StcSetClientGlobalStates.fromJson,
  CtsSetSceneState.messageClassS: CtsSetSceneState.fromJson,
  StcSetClientSceneStates.messageClassS: StcSetClientSceneStates.fromJson,
  StcRemoteChanges.messageClassS: StcRemoteChanges.fromJson,
  StcLocalChangeDecisions.messageClassS: StcLocalChangeDecisions.fromJson,
  CtsStateChanges.messageClassS: CtsStateChanges.fromJson,
  // PtpRpc.messageClassS: PtpRpc.fromJson,
  PtpAssetBlob.messageClassS: PtpAssetBlob.fromJson,
  CtsListenToAssetDirectory.messageClassS: CtsListenToAssetDirectory.fromJson,
  StcAssetDirectoryStreamUpdate.messageClassS: StcAssetDirectoryStreamUpdate.fromJson,
  CtsCreateAssets.messageClassS: CtsCreateAssets.fromJson,
  CtsDeleteAssets.messageClassS: CtsDeleteAssets.fromJson,
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

// @JsonSerializable()
// class PtpRpc extends Message {
//   final Map<String, dynamic> message;

//   PtpRpc({required this.message});

//   @override
//   String get messageClass => '$PtpRpc';
//   static String get messageClassS => '$PtpRpc';

//   factory PtpRpc.fromJson(Map<String, dynamic> json) => _$PtpJsonRpcFromJson(json);
//   Map<String, dynamic> toJson() => _$PtpJsonRpcToJson(this);
// }
