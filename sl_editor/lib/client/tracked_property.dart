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
  final String path;
  T _value;
  final T Function(dynamic)? _fromJson;
  final dynamic Function(T)? _toJson;
  final void Function(StateTracked, T)? _effect;
  final _onChangedController = StreamController<T>.broadcast();
  late final Stream<T> onChanged;

  TrackedProperty({
    required this.path,
    required T value,
    T Function(dynamic)? fromJson,
    dynamic Function(T)? toJson,
    void Function(StateTracked, T)? effect,
  }) : _value = value,
       _fromJson = fromJson,
       _toJson = toJson,
       _effect = effect {
    onChanged = _onChangedController.stream;
  }

  T get() {
    return _value;
  }

  void set(StateTracked effectReceiver, BiDeltaBuilder builder, T newValue) {
    builder.setProperty(
      path,
      _toJson == null ? _value : _toJson(_value),
      _toJson == null ? newValue : _toJson(newValue),
    );
    _effect?.call(effectReceiver, newValue);
    _value = newValue;
    _onChangedController.add(_value);
  }

  void getDeltaFromNullRelToObject(Delta builder) {
    builder[path] = _toJson == null ? _value : _toJson(_value);
  }

  void applyDeltaRelToObject(StateTracked effectReceiver, Delta delta) {
    if (!delta.containsKey(path)) return;
    T newValue;
    if (_fromJson != null) {
      newValue = _fromJson(delta[path]);
    } else {
      newValue = delta[path] as T;
    }
    _effect?.call(effectReceiver, newValue);
    _value = newValue;
    _onChangedController.add(_value);
  }
}
