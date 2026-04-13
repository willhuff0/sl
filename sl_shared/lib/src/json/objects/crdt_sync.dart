import 'package:json_annotation/json_annotation.dart';
import 'package:sl_shared/sl_shared.dart';

part 'crdt_sync.g.dart';

@JsonSerializable()
class PtpCrdtSync extends Message {
  final Map<String, dynamic> message;

  PtpCrdtSync({
    required this.message,
  });

  @override
  String get messageClass => '$PtpCrdtSync';
  static String get messageClassS => '$PtpCrdtSync';

  factory PtpCrdtSync.fromJson(Map<String, dynamic> json) => _$PtpCrdtSyncFromJson(json);

  Map<String, dynamic> toJson() => _$PtpCrdtSyncToJson(this);
}
