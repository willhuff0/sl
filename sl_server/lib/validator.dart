import 'package:sl_shared/sl_shared.dart';
import 'package:vector_math/vector_math.dart';

class Val<T> {
  T value;
  final String key;
  final bool Function(dynamic) validator;
  final void Function(Val<T>, dynamic)? setter;
  final bool required;

  Val(this.value, {required this.key, required this.validator, this.setter, this.required = false});

  bool validate(Delta delta) {
    if (!delta.containsKey(key)) return !required;
    return validator(delta[key]);
  }

  void set(Delta delta) {
    if (setter != null) {
      setter!(this, delta[key]);
    } else {
      value = delta[key];
    }
  }
}

bool vector3Validator(dynamic v) {
  if (v is! List<dynamic>) return false;
  if (v.length != 3) return false;
  if (v[0] is! double) return false;
  if (v[1] is! double) return false;
  if (v[2] is! double) return false;
  return true;
}

bool quaternionValidator(dynamic v) {
  if (v is! List<dynamic>) return false;
  if (v.length != 4) return false;
  if (v[0] is! double) return false;
  if (v[1] is! double) return false;
  if (v[2] is! double) return false;
  if (v[3] is! double) return false;
  return true;
}

void vector3Setter(Val o, dynamic v) {
  o.value = Vector3(v[0], v[1], v[2]);
}

void quaternionSetter(Val o, dynamic v) {
  o.value = Quaternion(v[0], v[1], v[2], v[3]);
}
