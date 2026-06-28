// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'parent_and_order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ParentAndOrder _$ParentAndOrderFromJson(Map<String, dynamic> json) =>
    ParentAndOrder(
      uuid: json['uuid'] as String,
      order: Fraction.fromJson(json['order'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ParentAndOrderToJson(ParentAndOrder instance) =>
    <String, dynamic>{'uuid': instance.uuid, 'order': instance.order.toJson()};
