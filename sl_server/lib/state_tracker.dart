import 'package:sl_server/objects/node.dart';
import 'package:sl_server/server.dart';
import 'package:sl_shared/sl_shared.dart';

final Map<ObjectClass, StateTracked Function(UUID)> _constructors = {
  Node.objectClass: Node.new,
};

abstract class StateTracked {
  final UUID uuid;

  StateTracked(this.uuid);

  bool isValid(Delta delta);
  void applyDelta(Delta delta);
}

class StateTracker {
  final Server _server;
  final Map<UUID, StateTracked> _trackedObjects = {};

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
      StcStateChanges(
        localChangeDecision: changeDecisions,
        remoteChanges: [],
      ),
    );
    _server.broadcast(
      StcStateChanges(
        localChangeDecision: {},
        remoteChanges: approvedChanges,
      ),
      except: {client},
    );
  }

  StateTracked? _loadObjectFromDisk(UUID uuid) {}

  StateTracked _createObject(ObjectClass objectClass, UUID uuid) {
    return _constructors[objectClass]!(uuid);
  }
}
