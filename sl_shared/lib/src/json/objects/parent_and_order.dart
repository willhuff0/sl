import 'package:json_annotation/json_annotation.dart';
import 'package:sl_shared/sl_shared.dart';
import 'package:uuid/uuid.dart';

part 'parent_and_order.g.dart';

@JsonSerializable()
class ParentAndOrder {
  final UUID uuid;
  final Fraction order;

  ParentAndOrder({
    required this.uuid,
    required this.order,
  });

  factory ParentAndOrder.fromJson(Map<String, dynamic> json) => _$ParentAndOrderFromJson(json);
  Map<String, dynamic> toJson() => _$ParentAndOrderToJson(this);

  bool isValid() {
    if (!Uuid.isValidUUID(fromString: uuid)) return false;
    if (!order.isValid()) return false;
    return true;
  }
}
