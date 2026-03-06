import 'dart:collection';
import 'package:meta/meta.dart';
import 'package:sl_editor/client/bi_delta.dart';
import 'package:sl_editor/client/objects/node.dart';
import 'package:sl_editor/client/tracked_property.dart';
import 'package:sl_shared/sl_shared.dart';

import 'client.dart';

final Map<ObjectClass, StateTracked Function(UUID)> _constructors = {
  Node.objectClass: Node.new,
};

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

  static final Map<ClientChangeId, StateChange> _changesSubmissionBuilder = {};
  static final Map<ClientChangeId, BiStateChange> _localChangesPendingDecision = {};
  static final SplayTreeMap<ClientChangeId, List<StateChange>> _remoteChanges = SplayTreeMap();
  static var _nextClientChangeId = 0;

  static T? getObject<T>(UUID objectId) {
    return _trackedObjects[objectId] as T?;
  }

  static void registerObject(UUID objectId, StateTracked object) {
    _trackedObjects[objectId] = object;
  }

  static void addLocalChange(BiStateChange biStateChange) {
    _changesSubmissionBuilder[_nextClientChangeId] = biStateChange.getForwardStateChange();
    _localChangesPendingDecision[_nextClientChangeId++] = biStateChange;
  }

  static bool hasLocalChanges() {
    return _changesSubmissionBuilder.isNotEmpty;
  }

  static void submitLocalChanges() {
    Client.get().send(
      CtsStateChanges(
        stateChanges: _changesSubmissionBuilder,
      ),
    );
    _changesSubmissionBuilder.clear();
  }

  static void handleChangeDecisions(StcLocalChangeDecisions changeDecisions) {
    changeDecisions.localChangeDecisions.forEach((localChangeId, decision) {
      final localBiStateChange = _localChangesPendingDecision[localChangeId]!;

      if (_remoteChanges.containsKey(localChangeId)) {
        assert(_remoteChanges.firstKey() == localChangeId);
        final remoteChangesToApply = _remoteChanges.values.first;

        _applyStateChange(localBiStateChange.getInverseStateChange());
        for (final remoteChange in remoteChangesToApply) {
          _applyStateChange(remoteChange);
        }
        if (decision) {
          _applyStateChange(localBiStateChange.getForwardStateChange());
        }

        _remoteChanges.remove(localChangeId);
      } else if (!decision) {
        _applyStateChange(localBiStateChange.getInverseStateChange());
      }
    });
  }

  static void handleRemoteChanges(StcRemoteChanges remoteChanges) {
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
