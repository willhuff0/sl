import 'package:json_annotation/json_annotation.dart';
import 'package:sl_shared/sl_shared.dart';

part 'protocol.g.dart';

typedef MessageFactory = Message Function(Map<String, dynamic> json);
final Map<String, MessageFactory> _factories = {
  StcSetSelf.messageClassS: StcSetSelf.fromJson,
  StcSetClientGlobalStates.messageClassS: StcSetClientGlobalStates.fromJson,

  // State Tracking
  StcRemoteChanges.messageClassS: StcRemoteChanges.fromJson,
  StcLocalChangeDecisions.messageClassS: StcLocalChangeDecisions.fromJson,
  CtsStateChanges.messageClassS: CtsStateChanges.fromJson,

  // Scenes
  CtsSetSceneState.messageClassS: CtsSetSceneState.fromJson,
  StcSetClientSceneStates.messageClassS: StcSetClientSceneStates.fromJson,

  // Assets
  CtsRequestAssetBlob.messageClassS: CtsRequestAssetBlob.fromJson,
  PtpAssetBlobStart.messageClassS: PtpAssetBlobStart.fromJson,
  PtpAssetBlobEnd.messageClassS: PtpAssetBlobEnd.fromJson,
  StcAssetBlobProgress.messageClassS: StcAssetBlobProgress.fromJson,
  PtpAssetBlobError.messageClassS: PtpAssetBlobError.fromJson,

  // Crdt Sync
  PtpCrdtSync.messageClassS: PtpCrdtSync.fromJson,
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
