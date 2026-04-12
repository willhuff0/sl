import 'package:meta/meta.dart';
import 'package:sl_server/objects/asset.dart';
import 'package:sl_server/objects/node.dart';
import 'package:sl_server/server.dart';
import 'package:sl_server/validated_property.dart';
import 'package:sl_shared/sl_shared.dart';

final Map<ObjectClass, StateTracked Function(StateTracker, UUID)> _constructors = {
  Node.objectClassS: Node.new,
  TrackedAsset.objectClassS: TrackedAsset.new,
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

  ObjectClass get objectClass;

  @mustCallSuper
  @mustBeOverridden
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
  @mustBeOverridden
  void applyDelta(Delta delta) {
    doesExist.set(this, delta);
  }

  @mustCallSuper
  @mustBeOverridden
  void getDeltaFromNull(Delta builder) {
    if (!doesExist.value) doesExist.getDeltaFromNull(builder);
  }
}

class StateTracker {
  final Server _server;
  final StateTrackerSystem _system;
  final Map<UUID, StateTracked> _trackedObjects = {};
  final Map<ClientId, ClientChangeId> _latestAcknowledgedChangeIds = {};

  final Set<Client> Function(UUID? scope, UUID uuid)? _getInterestedClients;
  final Future<StateTracked?> Function(UUID uuid)? _loadObjectFromDisk;

  StateTracker(
    this._server,
    this._system, {
    Set<Client> Function(UUID? scope, UUID uuid)? getInterestedClients,
    Future<StateTracked?> Function(UUID uuid)? loadObjectFromDisk,
  }) : _getInterestedClients = getInterestedClients,
       _loadObjectFromDisk = loadObjectFromDisk;

  StateTracked? getObjectInMemory(UUID uuid) {
    return _trackedObjects[uuid];
  }

  Future<StateTracked?> getObject(UUID uuid) async {
    var object = _trackedObjects[uuid];
    if (object == null) {
      object = await _loadObjectFromDisk?.call(uuid);
      if (object != null) {
        _trackedObjects[uuid] = object;
      }
    }
    return object;
  }

  Future<void> handleClientChanges(
    Client client,
    CtsStateChanges stateChanges, {
    void Function(StateTracked)? insertBuilder,
    void Function(Delta, StateTracked)? updateBuilder,
  }) async {
    final Map<ClientChangeId, bool> changeDecisions = {};
    final List<StateChange> approvedChanges = [];

    for (final entry in stateChanges.stateChanges.entries) {
      final clientChangeId = entry.key;
      final stateChange = entry.value;

      _latestAcknowledgedChangeIds[client.clientId] = clientChangeId;
      var trackedObject = _trackedObjects[stateChange.objectId];

      var wasObjectJustAdded = false;
      var wasObjectJustCreated = false;
      if (trackedObject == null) {
        trackedObject = await _loadObjectFromDisk?.call(stateChange.objectId);
        if (trackedObject == null) {
          if (stateChange.objectClass == null) {
            changeDecisions[clientChangeId] = false;
            print('Object ${stateChange.objectId} is not registered on the server!');
            return;
          }
          trackedObject = _createObject(stateChange.objectClass!, stateChange.objectId);
        } else {
          wasObjectJustCreated = true;
        }
        wasObjectJustAdded = true;
      }

      if (trackedObject.isValid(stateChange.delta)) {
        trackedObject.applyDelta(stateChange.delta);
        changeDecisions[clientChangeId] = true;
        approvedChanges.add(
          StateChange(
            scope: stateChange.scope,
            objectClass: stateChange.objectClass,
            objectId: stateChange.objectId,
            delta: stateChange.delta,
          ),
        );
        if (wasObjectJustAdded) {
          _trackedObjects[stateChange.objectId] = trackedObject;
        }
        if (wasObjectJustCreated) {
          insertBuilder?.call(trackedObject);
        } else {
          updateBuilder?.call(stateChange.delta, trackedObject);
        }
      } else {
        changeDecisions[clientChangeId] = false;
      }
    }

    _server.send(
      client,
      StcLocalChangeDecisions(
        system: _system,
        localChangeDecisions: changeDecisions,
      ),
    );
    if (approvedChanges.isNotEmpty) {
      if (_getInterestedClients != null) {
        final interestedClientsToChanges = <Client, List<StateChange>>{};
        for (final change in approvedChanges) {
          final interestedClients = _getInterestedClients(change.scope, change.objectId);
          for (final interestedClient in interestedClients) {
            if (interestedClient == client) continue;
            var interestingChanges = interestedClientsToChanges[client] ??= [];
            interestingChanges.add(change);
          }
        }
        interestedClientsToChanges.forEach((client, changes) {
          _server.send(
            client,
            StcRemoteChanges(
              system: _system,
              remoteChanges: changes,
              latestAcknowledgedChangeId: _latestAcknowledgedChangeIds[client.clientId] ?? 0,
            ),
          );
        });
      } else {
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
  }

  StateTracked _createObject(ObjectClass objectClass, UUID uuid) {
    return _constructors[objectClass]!(this, uuid);
  }

  void preloadObjectsForClient(Client client, UUID? scope, Iterable<StateTracked> objects) {
    final changes = <StateChange>[];
    for (final object in objects) {
      _trackedObjects[object.uuid] = object;

      final builder = <String, dynamic>{};
      object.getDeltaFromNull(builder);
      changes.add(
        StateChange(
          scope: scope,
          objectClass: object.objectClass,
          objectId: object.uuid,
          delta: builder,
        ),
      );
    }
    _server.send(
      client,
      StcRemoteChanges(
        system: _system,
        remoteChanges: changes,
        latestAcknowledgedChangeId: _latestAcknowledgedChangeIds[client.clientId] ?? 0,
      ),
    );
  }

  bool isObjectLoaded(UUID uuid) {
    return _trackedObjects.containsKey(uuid);
  }
}
