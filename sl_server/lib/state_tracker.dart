import 'package:meta/meta.dart';
import 'package:sl_server/objects/node.dart';
import 'package:sl_server/server.dart';
import 'package:sl_server/validated_property.dart';
import 'package:sl_shared/sl_shared.dart';

final Map<ObjectClass, StateTracked Function(StateTracker, UUID)> _constructors = {
  Node.objectClass: Node.new,
};

abstract class StateTracked {
  final StateTracker tracker;
  final UUID uuid;

  final ValidatedProperty<bool> doesExist = ValidatedProperty(
    true,
    key: 'doesExist',
    validator: (receiver, v) {
      if (v is! bool) return false;
      if (!receiver.doesExist.value && v) return false;
      return true;
    },
  );

  StateTracked(this.tracker, this.uuid);

  @mustCallSuper
  bool isValid(Delta delta) {
    try {
      if (!doesExist.value) return false;
      if (!doesExist.validate(this, delta)) return false;
      return true;
    } catch (_) {
      return false;
    }
  }

  @mustCallSuper
  void applyDelta(Delta delta) {
    doesExist.set(this, delta);
  }
}

class StateTracker {
  final Server _server;
  final StateTrackerSystem _system;
  final Map<UUID, StateTracked> _trackedObjects = {};
  final Map<ClientId, ClientChangeId> _latestAcknowledgedChangeIds = {};
  final StateTracked? Function(UUID uuid)? _loadObjectFromDisk;

  StateTracker(
    this._server,
    this._system, {
    StateTracked? Function(UUID uuid)? loadObjectFromDisk,
  }) : _loadObjectFromDisk = loadObjectFromDisk;

  StateTracked? getObject(UUID uuid) {
    var object = _trackedObjects[uuid];
    if (object == null) {
      object = _loadObjectFromDisk?.call(uuid);
      if (object != null) {
        _trackedObjects[uuid] = object;
      }
    }
    return object;
  }

  void handleClientChanges(Client client, CtsStateChanges stateChanges) {
    final Map<ClientChangeId, bool> changeDecisions = {};
    final List<StateChange> approvedChanges = [];

    stateChanges.stateChanges.forEach((clientChangeId, stateChange) {
      _latestAcknowledgedChangeIds[client.clientId] = clientChangeId;
      var trackedObject = _trackedObjects[stateChange.objectId];

      var wasObjectJustAdded = false;
      if (trackedObject == null) {
        trackedObject = _loadObjectFromDisk?.call(stateChange.objectId);
        if (trackedObject == null) {
          if (stateChange.objectClass == null) {
            changeDecisions[clientChangeId] = false;
            print('Object ${stateChange.objectId} is not registered on the server!');
            return;
          }
          trackedObject = _createObject(stateChange.objectClass!, stateChange.objectId);
        }
        wasObjectJustAdded = true;
      }

      if (trackedObject.isValid(stateChange.delta)) {
        changeDecisions[clientChangeId] = true;
        approvedChanges.add(
          StateChange(
            objectClass: stateChange.objectClass,
            objectId: stateChange.objectId,
            delta: stateChange.delta,
          ),
        );
        if (wasObjectJustAdded) {
          _trackedObjects[stateChange.objectId] = trackedObject;
        }
      } else {
        changeDecisions[clientChangeId] = false;
      }
    });

    _server.send(
      client,
      StcLocalChangeDecisions(
        system: _system,
        localChangeDecisions: changeDecisions,
      ),
    );
    if (approvedChanges.isNotEmpty) {
      _server.sendToEach((otherClient) {
        if (otherClient == client) return null;
        return StcRemoteChanges(
          system: _system,
          remoteChanges: approvedChanges,
          latestAcknowledgedChangeId: _latestAcknowledgedChangeIds[otherClient.clientId] ?? 0,
        );
      });
    }
  }

  StateTracked _createObject(ObjectClass objectClass, UUID uuid) {
    return _constructors[objectClass]!(this, uuid);
  }

  void preloadObjects(Iterable<StateTracked> objects) {
    for (final object in objects) {
      _trackedObjects[object.uuid] = object;
    }
  }
}
