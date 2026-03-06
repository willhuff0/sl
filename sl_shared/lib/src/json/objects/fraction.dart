import 'package:json_annotation/json_annotation.dart';

part 'fraction.g.dart';

BigInt _gcd(BigInt a, BigInt b) {
  while (b != BigInt.zero) {
    BigInt t = b;
    b = a % b;
    a = t;
  }
  return a;
}

@JsonSerializable()
class Fraction {
  final BigInt numerator;
  final BigInt denominator;

  Fraction({
    required this.numerator,
    required this.denominator,
  });

  factory Fraction.fromJson(Map<String, dynamic> json) => _$FractionFromJson(json);
  Map<String, dynamic> toJson() => _$FractionToJson(this);

  Fraction._(this.numerator, this.denominator);
  factory Fraction.unreduced(
    BigInt numerator,
    BigInt denominator,
  ) {
    if (denominator == BigInt.zero) throw Exception('Fraction denominator cannot be zero!');
    if (denominator < BigInt.zero) {
      return Fraction._(-numerator, -denominator);
    } else {
      return Fraction._(numerator, denominator);
    }
  }

  static Fraction get zero => Fraction.unreduced(BigInt.zero, BigInt.one);
  static Fraction get one => Fraction.unreduced(BigInt.one, BigInt.one);

  factory Fraction.reduced(BigInt numerator, BigInt denominator) {
    if (denominator == BigInt.zero) throw Exception('Fraction denominator cannot be zero!');
    final gcd = _gcd(numerator.abs(), denominator.abs());
    if (denominator < BigInt.zero) {
      return Fraction._(-numerator ~/ gcd, -denominator ~/ gcd);
    } else {
      return Fraction._(numerator ~/ gcd, denominator ~/ gcd);
    }
  }
  Fraction reduced() => Fraction.reduced(numerator, denominator);

  factory Fraction.midpoint(Fraction a, Fraction b) => Fraction.reduced(
    a.numerator * b.denominator + a.denominator * b.numerator,
    BigInt.two * a.denominator * b.denominator,
  );

  bool isValid() {
    if (denominator <= BigInt.zero) return false;
    return true;
  }

  Fraction operator +(Fraction other) => Fraction.reduced(
    numerator * other.denominator + denominator * other.numerator,
    denominator * other.denominator,
  );

  Fraction operator -(Fraction other) => Fraction.reduced(
    numerator * other.denominator - denominator * other.numerator,
    denominator * other.denominator,
  );

  Fraction operator *(Fraction other) => Fraction.reduced(
    numerator * other.numerator,
    denominator * other.denominator,
  );

  Fraction operator /(Fraction other) => Fraction.reduced(
    numerator * other.denominator,
    denominator * other.numerator,
  );

  bool operator <(Fraction other) => numerator * other.denominator < denominator * other.numerator;
  bool operator <=(Fraction other) => numerator * other.denominator <= denominator * other.numerator;
  bool operator >(Fraction other) => numerator * other.denominator > denominator * other.numerator;
  bool operator >=(Fraction other) => numerator * other.denominator >= denominator * other.numerator;
}
