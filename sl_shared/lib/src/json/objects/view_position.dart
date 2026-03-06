import 'package:json_annotation/json_annotation.dart';
import 'package:sl_shared/sl_shared.dart';

part 'view_position.g.dart';

@JsonSerializable()
class ViewPosition {
  final (double, double, double) position;
  final (double, double, double, double) orientation;
  final double fov;
  final (double, double) cursor;
  final Set<UUID> selection;

  ViewPosition({
    required this.position,
    required this.orientation,
    required this.fov,
    required this.cursor,
    required this.selection,
  });

  factory ViewPosition.fromJson(Map<String, dynamic> json) => _$ViewPositionFromJson(json);
  Map<String, dynamic> toJson() => _$ViewPositionToJson(this);
}
