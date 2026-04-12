import 'package:sl_server/state_tracker.dart';
import 'package:sl_shared/sl_shared.dart';
import 'package:vector_math/vector_math.dart';

class ValidatedProperty<T> {
  T value;
  final String key;
  final bool Function(StateTracked, dynamic) validator;
  final void Function(StateTracked, ValidatedProperty<T>, dynamic)? setter;
  final bool required;

  ValidatedProperty(
    this.value, {
    required this.key,
    required this.validator,
    this.setter,
    this.required = false,
  });

  bool validate(StateTracked receiver, Delta delta) {
    if (!delta.containsKey(key)) return !required;
    return validator(receiver, delta[key]);
  }

  void set(StateTracked receiver, Delta delta) {
    if (!delta.containsKey(key)) return;
    if (setter != null) {
      setter!(receiver, this, delta[key]);
    } else {
      value = delta[key];
    }
  }

  void getDeltaFromNull(Delta builder) {
    builder[key] = value;
  }
}

bool vector3Validator(_, dynamic v) {
  if (v is! List<dynamic>) return false;
  if (v.length != 3) return false;
  if (v[0] is! num) return false;
  if (v[1] is! num) return false;
  if (v[2] is! num) return false;
  return true;
}

bool quaternionValidator(_, dynamic v) {
  if (v is! List<dynamic>) return false;
  if (v.length != 4) return false;
  if (v[0] is! num) return false;
  if (v[1] is! num) return false;
  if (v[2] is! num) return false;
  if (v[3] is! num) return false;
  return true;
}

void vector3Setter(_, ValidatedProperty o, dynamic v) {
  o.value = Vector3(v[0].toDouble(), v[1].toDouble(), v[2].toDouble());
}

void quaternionSetter(_, ValidatedProperty o, dynamic v) {
  o.value = Quaternion(v[0].toDouble(), v[1].toDouble(), v[2].toDouble(), v[3].toDouble());
}
