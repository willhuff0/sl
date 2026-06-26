import 'package:sl_server/state_tracker.dart';
import 'package:sl_shared/sl_shared.dart';

class ValidatedProperty<T> {
  final PropertySchema<T> schema;
  T value;

  /// Receiver-dependent validation, run after the schema's pure value check passes. Used for
  /// rules that need the tracker or other object state (e.g. that a parent node exists).
  final bool Function(StateTracked receiver, dynamic value)? receiverValidator;

  /// Custom apply logic with side effects (e.g. reparenting). When null, the raw delta value is
  /// assigned directly.
  final void Function(StateTracked, ValidatedProperty<T>, dynamic)? setter;

  ValidatedProperty(
    this.schema, {
    this.receiverValidator,
    this.setter,
  }) : value = schema.createDefault();

  String get key => schema.key;

  bool validate(StateTracked receiver, Delta delta) {
    if (!delta.containsKey(key)) return !schema.required;
    final value = delta[key];
    if (schema.validateValue != null && !schema.validateValue!(value)) return false;
    if (receiverValidator != null && !receiverValidator!(receiver, value)) return false;
    return true;
  }

  void set(StateTracked receiver, Delta delta) {
    if (!delta.containsKey(key)) return;
    if (setter != null) {
      setter!(receiver, this, delta[key]);
    } else {
      value = delta[key];
    }
  }

  void getJson(Map<String, dynamic> builder) {
    builder[key] = schema.encode(value);
  }

  void setJson(Map<String, dynamic> json) {
    value = schema.decode(json[key]);
  }
}
