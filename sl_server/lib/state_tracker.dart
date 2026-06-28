import 'package:meta/meta.dart';
import 'package:sl_server/client.dart';
import 'package:sl_server/scenes/node.dart';
import 'package:sl_server/server.dart';
import 'package:sl_server/validated_property.dart';
import 'package:sl_shared/sl_shared.dart';

final Map<ObjectClass, StateTracked Function(StateTracker, UUID)> _constructors = {
  Node.objectClassS: Node.new,
};

abstract class StateTracked {
  final StateTracker tracker;
  final UUID uuid;

  final ValidatedProperty<bool> doesExist = ValidatedProperty(
    doesExistSchema,
    receiverValidator: (receiver, value) {
      if (value is! bool) return false;
      if (!receiver.doesExist.value && value) return false;
      return true;
    },
  );

  StateTracked(this.tracker, this.uuid);

  ObjectClass get objectClass;

  /// The properties declared by this object, in serialization order. Excludes [doesExist],
  /// which the base class handles specially.
  List<ValidatedProperty> get properties;

  /// [properties] plus [doesExist] (last), used for validation and applying deltas.
  late final List<ValidatedProperty> _allProperties = [...properties, doesExist];

  @nonVirtual
  bool isValid(Delta delta) {
    try {
      if (!doesExist.value) return false;
      return _allProperties.every((property) => property.validate(this, delta));
    } catch (_) {
      return false;
    }
  }

  @nonVirtual
  void applyDelta(Delta delta) {
    for (final property in _allProperties) {
      property.set(this, delta);
    }
  }

  @nonVirtual
  void getJson(Map<String, dynamic> builder) {
    for (final property in properties) {
      property.getJson(builder);
    }
    // doesExist is only serialized when false; existing objects omit it (default is true).
    if (!doesExist.value) doesExist.getJson(builder);
  }

  @nonVirtual
  void setJson(Map<String, dynamic> json) {
    // doesExist is intentionally not restored: only existing objects are persisted, so it
    // stays at its default of true.
    for (final property in properties) {
      property.setJson(json);
    }
  }

  @nonVirtual
  Map<String, dynamic> toJson() {
    final builder = Delta();
    getJson(builder);
    builder['class'] = objectClass;
    builder['uuid'] = uuid;
    return builder;
  }
}

class StateTracker {
  final Server _server;
  final UUID _sceneId;
  final Map<UUID, StateTracked> _trackedObjects = {};

  /// Monotonic total-order sequence assigned to every applied change in this scene. The authoritative
  /// ordering clients use to advance their confirmed layer. `-1` means nothing has been applied yet.
  ServerSeq _nextServerSeq = 0;
  ServerSeq get _latestSeq => _nextServerSeq - 1;

  final Set<Client> Function()? _getInterestedClients;
  final Future<StateTracked?> Function(UUID uuid)? _loadObjectFromDisk;

  StateTracker(
    this._server,
    this._sceneId, {
    Set<Client> Function()? getInterestedClients,
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

  void addObject(StateTracked object) async {
    _trackedObjects[object.uuid] = object;
  }

  Future<void> handleClientChanges(
    Client client,
    CtsStateChanges stateChanges, {
    void Function(StateTracked)? insertBuilder,
    void Function(Delta, StateTracked)? updateBuilder,
  }) async {
    // Approved changes, paired with the authoring client's change id so we can stamp `originChangeId`
    // on the author's copy of the log (and leave it null for everyone else).
    final List<(ClientChangeId, AppliedChange)> approved = [];
    final List<ClientChangeId> rejectedLocalChanges = [];

    for (final entry in stateChanges.stateChanges.entries) {
      final clientChangeId = entry.key;
      final stateChange = entry.value;

      var trackedObject = _trackedObjects[stateChange.objectId];

      var wasObjectJustAdded = false;
      var wasObjectJustCreated = false;
      if (trackedObject == null) {
        trackedObject = await _loadObjectFromDisk?.call(stateChange.objectId);
        if (trackedObject == null) {
          if (stateChange.objectClass == null) {
            rejectedLocalChanges.add(clientChangeId);
            print('Object ${stateChange.objectId} is not registered on the server!');
            continue;
          }
          trackedObject = _createObject(stateChange.objectClass!, stateChange.objectId);
        } else {
          wasObjectJustCreated = true;
        }
        wasObjectJustAdded = true;
      }

      if (trackedObject.isValid(stateChange.delta)) {
        trackedObject.applyDelta(stateChange.delta);
        final serverSeq = _nextServerSeq++;
        approved.add((
          clientChangeId,
          AppliedChange(
            serverSeq: serverSeq,
            objectClass: stateChange.objectClass,
            objectId: stateChange.objectId,
            delta: stateChange.delta,
          ),
        ));
        if (wasObjectJustAdded) {
          _trackedObjects[stateChange.objectId] = trackedObject;
        }
        if (wasObjectJustCreated) {
          insertBuilder?.call(trackedObject);
        } else {
          updateBuilder?.call(stateChange.delta, trackedObject);
        }
      } else {
        rejectedLocalChanges.add(clientChangeId);
      }
    }

    if (approved.isEmpty && rejectedLocalChanges.isEmpty) return;

    final firstSeq = approved.isEmpty ? -1 : approved.first.$2.serverSeq;
    final interestedClients = _getInterestedClients?.call();

    _server.sendToEach((otherClient) {
      final isAuthor = otherClient == client;
      if (!isAuthor && interestedClients != null && !interestedClients.contains(otherClient)) return null;
      // The author always gets a message (it carries its acks/rejections); peers only when something
      // was actually applied.
      if (!isAuthor && approved.isEmpty) return null;

      final changes = [
        for (final (changeId, change) in approved)
          AppliedChange(
            serverSeq: change.serverSeq,
            originChangeId: isAuthor ? changeId : null,
            objectClass: change.objectClass,
            objectId: change.objectId,
            delta: change.delta,
          ),
      ];

      return StcStateLog(
        sceneId: _sceneId,
        firstSeq: firstSeq,
        changes: changes,
        rejectedLocalChanges: isAuthor ? rejectedLocalChanges : const [],
      );
    });
  }

  StateTracked _createObject(ObjectClass objectClass, UUID uuid) {
    return _constructors[objectClass]!(this, uuid);
  }

  void sendAllToClient(Client client, String rootUuid) {
    final objects = <StateChange>[];
    void addObject(Node object) {
      _trackedObjects[object.uuid] = object;

      final builder = <String, dynamic>{};
      object.getJson(
        builder,
      ); // TODO: should use a different method (potentially different representation for saving on server vs client)
      objects.add(
        StateChange(
          objectClass: object.objectClass,
          objectId: object.uuid,
          delta: builder,
        ),
      );

      for (final child in object.children.values) {
        addObject(getObjectInMemory(child) as Node);
      }
    }

    // add in-order for loading (parents before children)
    addObject(getObjectInMemory(rootUuid) as Node);

    _server.send(
      client,
      StcStateSnapshot(
        sceneId: _sceneId,
        baseServerSeq: _latestSeq,
        objects: objects,
      ),
    );
  }

  bool isObjectLoaded(UUID uuid) {
    return _trackedObjects.containsKey(uuid);
  }

  Map<String, dynamic> toJson() => {
    'objects': Map.fromEntries(
      _trackedObjects.entries
          .where((entry) => entry.value.doesExist.value)
          .map((entry) => MapEntry(entry.key, entry.value.toJson())),
    ),
  };

  void fromJson(Map<String, dynamic> json) {
    final objects = json['objects'] as Map<String, dynamic>? ?? {};
    for (final entry in objects.entries) {
      final uuid = entry.key;
      final objectJson = entry.value;

      final object = _createObject(objectJson['class']!, uuid);
      object.setJson(objectJson);
      _trackedObjects[object.uuid] = object;
    }

    // link children
    for (final entry in _trackedObjects.entries) {
      final uuid = entry.key;
      final object = entry.value;

      if (object is! Node) continue;

      if (object.parent.value != null) {
        final parent = getObjectInMemory(object.parent.value!.uuid) as Node;
        parent.children[object.parent.value!.order] = uuid;
      }
    }
  }
}
