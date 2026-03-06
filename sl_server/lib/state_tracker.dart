import 'package:sl_server/objects/node.dart';
import 'package:sl_server/server.dart';
import 'package:sl_shared/sl_shared.dart';

final Map<ObjectClass, StateTracked Function(StateTracker, UUID)> _constructors = {
  Node.objectClass: Node.new,
};

abstract class StateTracked {
  final StateTracker tracker;
  final UUID uuid;

  StateTracked(this.tracker, this.uuid);

  bool isValid(Delta delta);
  void applyDelta(Delta delta);
}

class StateTracker {
  final Server _server;
  final Map<UUID, StateTracked> _trackedObjects = {};
  final Map<ClientId, ClientChangeId> _latestAcknowledgedChangeIds = {};

  StateTracker(Server server) : _server = server;

  StateTracked? getObject(UUID uuid) {
    var object = _trackedObjects[uuid];
    if (object == null) {
      object = _loadObjectFromDisk(uuid);
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
        trackedObject = _loadObjectFromDisk(stateChange.objectId);
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
        localChangeDecisions: changeDecisions,
      ),
    );
    if (approvedChanges.isNotEmpty) {
      _server.sendToEach((otherClient) {
        if (otherClient == client) return null;
        return StcRemoteChanges(
          remoteChanges: approvedChanges,
          latestAcknowledgedChangeId: _latestAcknowledgedChangeIds[otherClient.clientId] ?? 0,
        );
      });
    }
  }

  StateTracked? _loadObjectFromDisk(UUID uuid) {}

  StateTracked _createObject(ObjectClass objectClass, UUID uuid) {
    return _constructors[objectClass]!(this, uuid);
  }
}
