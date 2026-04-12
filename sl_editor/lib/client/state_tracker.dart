import 'dart:collection';
import 'package:meta/meta.dart';
import 'package:sl_editor/client/bi_delta.dart';
import 'package:sl_editor/client/tracked_property.dart';
import 'package:sl_shared/sl_shared.dart';

import 'client.dart';

abstract class StateTracked {
  final StateTracker tracker;
  final UUID uuid;
  final TrackedProperty<bool> doesExist;

  StateTracked(this.tracker, this.uuid, {void Function(StateTracked self, bool doesExist)? doesExistEffect})
    : doesExist = TrackedProperty(path: 'doesExist', value: true, effect: doesExistEffect);

  @protected
  @nonVirtual
  void createThis(String objectClass) {
    final builder = Delta();
    getDeltaFromNull(builder);
    tracker.registerObject(this);
    tracker.addLocalChange(
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
    tracker.addLocalChange(
      BiStateChange(
        objectId: uuid,
        biDelta: builder.getBiDelta(),
      ),
    );
  }

  @mustCallSuper
  @mustBeOverridden
  void getDeltaFromNull(Delta builder) {
    if (!doesExist.get()) doesExist.getDeltaFromNullRelToObject(builder);
  }

  @mustCallSuper
  @mustBeOverridden
  void applyDelta(Delta delta) {
    doesExist.applyDeltaRelToObject(this, delta);
  }
}

class StateTracker<T extends StateTracked> {
  final Map<ObjectClass, T Function(StateTracker, UUID)> constructors;

  final void Function(T object)? onObjectAdded;
  final void Function(T object)? onObjectRemoved;

  final StateTrackerSystem system;

  final Map<UUID, T> _trackedObjects = {};
  final Map<ClientChangeId, StateChange> _changesSubmissionBuilder = {};
  final Map<ClientChangeId, BiStateChange> _localChangesPendingDecision = {};
  final SplayTreeMap<ClientChangeId, List<StateChange>> _remoteChanges = SplayTreeMap();
  var _nextClientChangeId = 0;

  UUID? _scope;

  StateTracker(
    this.system, {
    required this.constructors,
    this.onObjectAdded,
    this.onObjectRemoved,
  });

  O? getObject<O extends T>(UUID objectId) {
    return _trackedObjects[objectId] as O?;
  }

  UnmodifiableMapView<UUID, T> getObjects() {
    return UnmodifiableMapView(_trackedObjects);
  }

  void changeScope(UUID? newScope) {
    if (hasLocalChanges()) {
      submitLocalChanges();
    }

    _trackedObjects.clear();
    _changesSubmissionBuilder.clear();
    _localChangesPendingDecision.clear();
    _remoteChanges.clear();

    _scope = newScope;
  }

  void registerObject(T object) {
    _trackedObjects[object.uuid] = object;
    onObjectAdded?.call(object);
  }

  void addLocalChange(BiStateChange biStateChange) {
    _changesSubmissionBuilder[_nextClientChangeId] = biStateChange.getForwardStateChange(_scope);
    _localChangesPendingDecision[_nextClientChangeId++] = biStateChange;
  }

  bool hasLocalChanges() {
    return _changesSubmissionBuilder.isNotEmpty;
  }

  void submitLocalChanges() {
    Client.get().send(
      CtsStateChanges(
        system: system,
        stateChanges: _changesSubmissionBuilder,
      ),
    );
    _changesSubmissionBuilder.clear();
  }

  void handleChangeDecisions(StcLocalChangeDecisions changeDecisions) {
    changeDecisions.localChangeDecisions.forEach((localChangeId, decision) {
      final localBiStateChange = _localChangesPendingDecision[localChangeId];
      if (localBiStateChange == null) {
        // state tracker has been cleared between sending and response
        return;
      }

      if (_remoteChanges.containsKey(localChangeId)) {
        assert(_remoteChanges.firstKey() == localChangeId);
        final remoteChangesToApply = _remoteChanges.values.first;

        _applyStateChange(localBiStateChange.getInverseStateChange(_scope));
        for (final remoteChange in remoteChangesToApply) {
          _applyStateChange(remoteChange);
        }
        if (decision) {
          _applyStateChange(localBiStateChange.getForwardStateChange(_scope));
        }

        _remoteChanges.remove(localChangeId);
      } else if (!decision) {
        _applyStateChange(localBiStateChange.getInverseStateChange(_scope));
      }
    });
  }

  void handleRemoteChanges(StcRemoteChanges remoteChanges) {
    if (_localChangesPendingDecision.isEmpty || remoteChanges.latestAcknowledgedChangeId >= _nextClientChangeId - 1) {
      assert(_localChangesPendingDecision.isEmpty);
      assert(remoteChanges.latestAcknowledgedChangeId >= _nextClientChangeId - 1);
      for (final stateChange in remoteChanges.remoteChanges) {
        _applyStateChange(stateChange);
      }
    } else {
      var remoteChangeList = _remoteChanges[remoteChanges.latestAcknowledgedChangeId];
      remoteChangeList ??= _remoteChanges[remoteChanges.latestAcknowledgedChangeId] = [];
      remoteChangeList.addAll(remoteChanges.remoteChanges);
    }
  }

  void tick() {
    if (hasLocalChanges()) {
      submitLocalChanges();
    }
  }

  void _applyStateChange(StateChange stateChange) {
    var trackedObject = _trackedObjects[stateChange.objectId];

    if (trackedObject == null) {
      if (stateChange.objectClass == null) {
        throw Exception('Object ${stateChange.objectId} is not registered on the client!');
      }
      trackedObject = _createObject(
        stateChange.objectClass!,
        stateChange.objectId,
      );
      registerObject(trackedObject);
    }

    trackedObject.applyDelta(stateChange.delta);
    if (onObjectRemoved != null && !trackedObject.doesExist.get()) {
      onObjectRemoved!(trackedObject);
    }
  }

  T _createObject(ObjectClass objectClass, UUID uuid) {
    return constructors[objectClass]!(this, uuid);
  }
}
