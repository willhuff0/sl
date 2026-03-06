// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fraction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Fraction _$FractionFromJson(Map<String, dynamic> json) => Fraction(
  numerator: BigInt.parse(json['numerator'] as String),
  denominator: BigInt.parse(json['denominator'] as String),
);

Map<String, dynamic> _$FractionToJson(Fraction instance) => <String, dynamic>{
  'numerator': instance.numerator.toString(),
  'denominator': instance.denominator.toString(),
};
