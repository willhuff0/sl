import 'dart:async';
import 'dart:collection';

import 'package:sl_editor/client/bi_delta.dart';
import 'package:sl_editor/client/state_tracker.dart';
import 'package:sl_shared/sl_shared.dart';

class StateChangesBuilder {
  final List<BiStateChange> _changes = [];

  void addStateChange(BiStateChange change) {
    _changes.add(change);
  }

  void reset() {
    _changes.clear();
  }

  UnmodifiableListView<BiStateChange> getChanges() {
    return UnmodifiableListView(_changes);
  }
}

class TrackedProperty<T> {
  final PropertySchema<T> schema;
  T _value;

  /// Side effect run when the value changes, used to push state into the engine.
  final void Function(StateTracked, T)? _effect;
  final _onChangedController = StreamController<T>.broadcast();
  late final Stream<T> onChanged;

  TrackedProperty(
    this.schema, {
    void Function(StateTracked, T)? effect,
  }) : _value = schema.createDefault(),
       _effect = effect {
    onChanged = _onChangedController.stream;
  }

  String get key => schema.key;
  T get value => _value;

  // T get() {
  //   return _value;
  // }

  void set(StateTracked effectReceiver, BiDeltaBuilder builder, T newValue) {
    builder.setProperty(
      key,
      schema.encode(_value),
      schema.encode(newValue),
    );
    _effect?.call(effectReceiver, newValue);
    _value = newValue;
    _onChangedController.add(_value);
  }

  void getDeltaFromNullRelToObject(Delta builder) {
    builder[key] = schema.encode(_value);
  }

  void applyDeltaRelToObject(StateTracked effectReceiver, Delta delta) {
    if (!delta.containsKey(key)) return;
    final newValue = schema.decode(delta[key]);
    _effect?.call(effectReceiver, newValue);
    _value = newValue;
    _onChangedController.add(_value);
  }
}
