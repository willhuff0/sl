import 'dart:collection';

import 'package:meta/meta.dart';
import 'package:sl_shared/sl_shared.dart';

import 'client.dart';

final Map<ObjectClass, StateTracked Function()> _constructors = {};

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

  TrackedProperty(
    this.path,
    T value, {
    T Function(dynamic)? fromJson,
  }) : _value = value,
       _fromJson = fromJson;

  T get() {
    return _value;
  }

  void set(BiDeltaBuilder builder, T newValue) {
    builder.setProperty(path, _value, newValue);
    _value = newValue;
  }

  void getDeltaFromNullRelToObject(Delta builder) {
    builder[path] = _value;
  }

  void applyDeltaRelToObject(Delta delta) {
    if (_fromJson != null) {
      _value = _fromJson(delta[path]);
    } else {
      _value = delta[path] as T;
    }
  }
}

abstract class StateTracked {
  final UUID uuid;
  final TrackedProperty<bool> doesExist = TrackedProperty('doesExist', true);

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
    doesExist.applyDeltaRelToObject(delta);
  }
}

class StateTracker {
  static final Map<UUID, StateTracked> _trackedObjects = {};

  static final List<BiStateChange> _changesSubmissionBuilder = [];
  static final Map<ClientChangeId, StateChange> _localChangesInverses = {};
  static final List<StateChange> _remoteChanges = [];
  static var _nextClientChangeId = 0;

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
      trackedObject = _trackedObjects[stateChange.objectId] = _createObject(stateChange.objectClass!);
    }

    trackedObject.applyDelta(stateChange.delta);
  }

  static StateTracked _createObject(ObjectClass objectClass) {
    return _constructors[objectClass]!();
  }
}
