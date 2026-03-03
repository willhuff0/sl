import 'dart:async';
import 'dart:collection';
import 'package:meta/meta.dart';
import 'package:sl_editor/client/objects/node.dart';
import 'package:sl_shared/sl_shared.dart';

import 'client.dart';

final Map<ObjectClass, StateTracked Function(UUID)> _constructors = {
  Node.objectClass: Node.new,
};

class BiDelta {
  final Delta delta;
  final Delta inverseDelta;

  BiDelta({
    required this.delta,
    required this.inverseDelta,
  });
}

class BiDeltaBuilder {
  final Delta _inverseDelta = {};
  final Delta _delta = {};

  void setProperty(String path, dynamic oldValue, dynamic newValue) {
    _inverseDelta[path] = oldValue;
    _delta[path] = newValue;
  }

  BiDelta getBiDelta() {
    return BiDelta(
      delta: _delta,
      inverseDelta: _inverseDelta,
    );
  }
}

class BiStateChange {
  final ObjectClass? objectClass;
  final UUID objectId;
  final BiDelta biDelta;

  BiStateChange({
    this.objectClass,
    required this.objectId,
    required this.biDelta,
  });
}

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

  // dynamic fromFieldString(String str) {
  //   return propertyFromFieldString<T>(str);
  // }

  // String getFieldTypeName() {
  //   return T.toString();
  // }
}

abstract class StateTracked {
  final UUID uuid;
  final TrackedProperty<bool> doesExist = TrackedProperty(path: 'doesExist', value: true);

  StateTracked(this.uuid);

  @protected
  @nonVirtual
  void createThis(String objectClass) {
    final builder = Delta();
    getDeltaFromNull(builder);
    StateTracker.registerObject(uuid, this);
    StateTracker.addLocalChange(
      BiStateChange(
        objectClass: objectClass,
        objectId: uuid,
        biDelta: BiDelta(
          delta: builder,
          inverseDelta: {
            'doesExist': false,
          },
        ),
      ),
    );
  }

  @nonVirtual
  void modifyLocal(void Function(BiDeltaBuilder) func) {
    final builder = BiDeltaBuilder();
    func(builder);
    StateTracker.addLocalChange(
      BiStateChange(
        objectId: uuid,
        biDelta: builder.getBiDelta(),
      ),
    );
  }

  @mustCallSuper
  @mustBeOverridden
  void getDeltaFromNull(Delta builder) {
    doesExist.getDeltaFromNullRelToObject(builder);
  }

  @mustCallSuper
  @mustBeOverridden
  void applyDelta(Delta delta) {
    doesExist.applyDeltaRelToObject(this, delta);
  }
}

class StateTracker {
  static final Map<UUID, StateTracked> _trackedObjects = {};

  static final List<BiStateChange> _changesSubmissionBuilder = [];
  static final Map<ClientChangeId, StateChange> _localChangesInverses = {};
  static final List<StateChange> _remoteChanges = [];
  static var _nextClientChangeId = 0;

  static T? getObject<T>(UUID objectId) {
    return _trackedObjects[objectId] as T?;
  }

  static void registerObject(UUID objectId, StateTracked object) {
    _trackedObjects[objectId] = object;
  }

  static void addLocalChange(BiStateChange change) {
    _changesSubmissionBuilder.add(change);
  }

  static bool hasLocalChanges() {
    return _changesSubmissionBuilder.isNotEmpty;
  }

  static void submitLocalChanges() {
    final Map<ClientChangeId, StateChange> changesToSend = {};

    for (final biStateChange in _changesSubmissionBuilder) {
      changesToSend[_nextClientChangeId] = StateChange(
        objectClass: biStateChange.objectClass,
        objectId: biStateChange.objectId,
        delta: biStateChange.biDelta.delta,
      );
      _localChangesInverses[_nextClientChangeId++] = StateChange(
        objectClass: biStateChange.objectClass,
        objectId: biStateChange.objectId,
        delta: biStateChange.biDelta.inverseDelta,
      );
    }
    _changesSubmissionBuilder.clear();

    Client.get().send(
      CtsStateChanges(
        stateChanges: changesToSend,
      ),
    );
  }

  static void handleRemoteChanges(StcStateChanges stateChanges) {
    stateChanges.localChangeDecision.forEach((clientChangeId, decision) {
      if (!decision) {
        _applyStateChange(_localChangesInverses[clientChangeId]!);
      }
      _localChangesInverses.remove(clientChangeId);
    });
    _remoteChanges.addAll(stateChanges.remoteChanges);
    if (_localChangesInverses.isEmpty) {
      for (final change in _remoteChanges) {
        _applyStateChange(change);
      }
      _remoteChanges.clear();
    }
  }

  static void _applyStateChange(StateChange stateChange) {
    var trackedObject = _trackedObjects[stateChange.objectId];

    if (trackedObject == null) {
      if (stateChange.objectClass == null) {
        throw Exception('Object ${stateChange.objectId} is not registered on the client!');
      }
      trackedObject = _trackedObjects[stateChange.objectId] = _createObject(
        stateChange.objectClass!,
        stateChange.objectId,
      );
    }

    trackedObject.applyDelta(stateChange.delta);
  }

  static StateTracked _createObject(ObjectClass objectClass, UUID uuid) {
    return _constructors[objectClass]!(uuid);
  }
}
