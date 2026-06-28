import 'dart:collection';
import 'package:meta/meta.dart';
import 'package:sl_editor/client/tracked_property.dart';
import 'package:sl_shared/sl_shared.dart';

import 'client.dart';

/// A single un-acknowledged local change, retained so it can be replayed on top of the confirmed
/// layer during every recompute. Forward-only — the rebase model never needs an inverse.
class PendingChange {
  final ClientChangeId id;
  final ObjectClass? objectClass;
  final UUID objectId;
  final Delta delta;

  PendingChange({
    required this.id,
    this.objectClass,
    required this.objectId,
    required this.delta,
  });

  StateChange toStateChange() => StateChange(objectClass: objectClass, objectId: objectId, delta: delta);
}

/// Base class for client-tracked objects in the rebase reconciliation model.
///
/// Existence is itself a tracked property ([doesExist]) with three layers. An object starts
/// non-existent in every layer; a change that carries an [ObjectClass] bootstraps existence in the
/// layer it is applied to. The tracker drives [realizeCreate]/[realizeDestroy] off the diff between
/// the optimistic and realized existence, and per-property updates off [flushPropertyEffects].
abstract class StateTracked {
  final StateTracker tracker;
  final UUID uuid;
  final TrackedProperty<bool> doesExist;

  bool _realizedExists = false;

  StateTracked(this.tracker, this.uuid) : doesExist = TrackedProperty(doesExistSchema) {
    // Override the schema default (true): an object is non-existent until a create bootstraps it.
    doesExist.setConfirmed(false);
    doesExist.setOptimistic(false);
    doesExist.markRealized();
  }

  /// The properties declared by this object, in delta order. Excludes [doesExist], which the base
  /// class handles specially.
  List<TrackedProperty> get properties;

  /// [properties] plus [doesExist] (last), used for applying deltas across all layers.
  late final List<TrackedProperty> _allProperties = [...properties, doesExist];

  bool get confirmedExists => doesExist.confirmedValue;
  bool get optimisticExists => doesExist.value;
  bool get realizedExists => _realizedExists;

  // --- confirmed layer -------------------------------------------------------------------------

  @nonVirtual
  void bootstrapConfirmedExists() => doesExist.setConfirmed(true);

  @nonVirtual
  void applyConfirmedDelta(Delta delta) {
    for (final property in _allProperties) {
      property.applyConfirmed(delta);
    }
  }

  // --- optimistic layer ------------------------------------------------------------------------

  @nonVirtual
  void resetOptimisticToConfirmed() {
    for (final property in _allProperties) {
      property.resetOptimisticToConfirmed();
    }
  }

  @nonVirtual
  void bootstrapOptimisticExists() => doesExist.setOptimistic(true);

  @nonVirtual
  void applyOptimisticDelta(Delta delta) {
    for (final property in _allProperties) {
      property.applyOptimistic(delta);
    }
  }

  // --- effect flushing -------------------------------------------------------------------------

  /// Per-property diff to engine, for objects that exist in both the optimistic and realized layers.
  /// Existence transitions are handled by the tracker via [realizeCreate]/[realizeDestroy].
  @nonVirtual
  void flushPropertyEffects() {
    for (final property in properties) {
      property.flushEffect(this);
    }
  }

  @nonVirtual
  void markAllRealized() {
    for (final property in _allProperties) {
      property.markRealized();
    }
  }

  /// Brings the object fully into the engine from its current optimistic state. Called once by the
  /// tracker when the object transitions to optimistically-existing. Implementations must leave
  /// realized engine state consistent with the optimistic values (the tracker then calls
  /// [markAllRealized]).
  void realizeCreate();

  /// Tears the object out of the engine. Called by the tracker when it transitions to optimistically
  /// non-existent.
  void realizeDestroy();

  // --- local edits -----------------------------------------------------------------------------

  /// Stages a forward-only delta produced by [func] as a pending local change.
  @nonVirtual
  void modifyLocal(void Function(Delta builder) func) {
    final builder = Delta();
    func(builder);
    if (builder.isEmpty) return;
    tracker.addLocalChange(uuid, builder);
  }

  @protected
  @nonVirtual
  void createThis(String objectClass, void Function(Delta builder) stageExtra) {
    final builder = Delta();
    for (final property in properties) {
      property.stageFromNull(builder);
    }
    stageExtra(builder);
    tracker.addLocalCreate(this, objectClass, builder);
  }
}

class StateTracker<T extends StateTracked> {
  final String sceneId;

  final Map<ObjectClass, T Function(StateTracker, UUID)> constructors;

  final Map<UUID, T> _trackedObjects = {};

  /// Un-acknowledged local changes, replayed (in id order) on top of the confirmed layer.
  final SplayTreeMap<ClientChangeId, PendingChange> _pending = SplayTreeMap();

  /// Changes staged but not yet sent to the server, flushed each tick.
  final Map<ClientChangeId, StateChange> _outbox = {};

  var _nextClientChangeId = 0;

  /// The latest authoritative sequence reflected in the confirmed layer. '-1' = nothing applied.
  ServerSeq _confirmedServerSeq = -1;

  var _recomputing = false;
  var _recomputeQueued = false;

  StateTracker({
    required this.sceneId,
    required this.constructors,
  });

  O? getObject<O extends T>(UUID objectId) {
    return _trackedObjects[objectId] as O?;
  }

  UnmodifiableMapView<UUID, T> getObjects() {
    return UnmodifiableMapView(_trackedObjects);
  }

  // --- local edits -----------------------------------------------------------------------------

  void addLocalChange(UUID objectId, Delta delta) {
    final id = _nextClientChangeId++;
    final pc = PendingChange(id: id, objectId: objectId, delta: delta);
    _pending[id] = pc;
    _outbox[id] = pc.toStateChange();
    _recompute();
  }

  void addLocalCreate(T object, ObjectClass objectClass, Delta delta) {
    // Register the caller's instance so replay reuses it (rather than constructing a duplicate).
    _trackedObjects[object.uuid] = object;
    final id = _nextClientChangeId++;
    final pc = PendingChange(id: id, objectClass: objectClass, objectId: object.uuid, delta: delta);
    _pending[id] = pc;
    _outbox[id] = pc.toStateChange();
    _recompute();
  }

  bool hasLocalChanges() => _outbox.isNotEmpty;

  void submitLocalChangesIfPresent() {
    if (_outbox.isNotEmpty) submitLocalChanges();
  }

  void submitLocalChanges() {
    Client.get().send(
      CtsStateChanges(
        sceneId: sceneId,
        stateChanges: Map.of(_outbox),
      ),
    );
    _outbox.clear();
  }

  // --- server messages -------------------------------------------------------------------------

  void handleStateLog(StcStateLog log) {
    if (log.changes.isNotEmpty) {
      if (log.firstSeq != _confirmedServerSeq + 1) {
        // Sequence gap (lost/reordered/duplicated) - heal by requesting a fresh snapshot.
        _requestResync();
        return;
      }
      for (final ac in log.changes) {
        _applyConfirmed(ac.objectClass, ac.objectId, ac.delta);
        _confirmedServerSeq = ac.serverSeq;
        if (ac.originChangeId != null) {
          _pending.remove(ac.originChangeId);
          _outbox.remove(ac.originChangeId);
        }
      }
    }
    for (final id in log.rejectedLocalChanges) {
      _pending.remove(id);
      _outbox.remove(id);
    }
    _recompute();
  }

  void handleSnapshot(StcStateSnapshot snapshot) {
    _resyncRequested = false;
    // Mark every tracked object confirmed-not-existing; the snapshot revives the survivors. Objects
    // absent from the snapshot fall out of the confirmed layer and are torn down on recompute.
    for (final obj in _trackedObjects.values) {
      obj.doesExist.setConfirmed(false);
    }
    for (final sc in snapshot.objects) {
      _applyConfirmed(sc.objectClass, sc.objectId, sc.delta);
    }
    _confirmedServerSeq = snapshot.baseServerSeq;
    _recompute();
  }

  void _applyConfirmed(ObjectClass? objectClass, UUID objectId, Delta delta) {
    var obj = _trackedObjects[objectId];
    if (obj == null) {
      if (objectClass == null) {
        // The server references an object we don't know about - we are desynced.
        _requestResync();
        return;
      }
      obj = _createObject(objectClass, objectId);
      _trackedObjects[objectId] = obj;
    }
    if (objectClass != null) obj.bootstrapConfirmedExists();
    obj.applyConfirmedDelta(delta);
  }

  var _resyncRequested = false;
  void _requestResync() {
    // Coalesce: one outstanding resync request is enough until the snapshot arrives.
    if (_resyncRequested) return;
    _resyncRequested = true;
    Client.get().send(CtsRequestResync(sceneId: sceneId));
  }

  // --- recompute (rebase) ----------------------------------------------------------------------

  void _recompute() {
    if (_recomputing) {
      // Re-entrant edit (e.g. a reconcile staged a local change) - fold into the running pass.
      _recomputeQueued = true;
      return;
    }
    _recomputing = true;
    try {
      do {
        _recomputeQueued = false;
        _recomputeOnce();
      } while (_recomputeQueued);
    } finally {
      _recomputing = false;
    }
  }

  void _recomputeOnce() {
    // 1. Reset optimistic to confirmed.
    for (final obj in _trackedObjects.values) {
      obj.resetOptimisticToConfirmed();
    }

    // 2. Replay pending changes in id order (global order respects create-parent-before-child).
    for (final pc in _pending.values) {
      var obj = _trackedObjects[pc.objectId];
      if (obj == null) {
        if (pc.objectClass == null) continue; // dangling change; target no longer exists
        obj = _createObject(pc.objectClass!, pc.objectId);
        _trackedObjects[pc.objectId] = obj;
      }
      if (pc.objectClass != null) obj.bootstrapOptimisticExists();
      obj.applyOptimisticDelta(pc.delta);
    }

    // 3. Diff to engine.
    _flushEffects();

    // 4. Drop objects that exist in no layer.
    _trackedObjects.removeWhere(
      (_, obj) => !obj.confirmedExists && !obj.optimisticExists && !obj.realizedExists,
    );
  }

  void _flushEffects() {
    final objects = _trackedObjects.values.toList(growable: false);

    // Phase A: realize creations, parent-first (insertion order is topological).
    for (final obj in objects) {
      if (obj.optimisticExists && !obj.realizedExists) {
        obj.realizeCreate();
        obj._realizedExists = true;
        obj.markAllRealized();
      }
    }

    // Phase B: incremental per-property updates for objects realized and still existing.
    for (final obj in objects) {
      if (obj.optimisticExists && obj.realizedExists) {
        obj.flushPropertyEffects();
      }
    }

    // Phase C: teardown, children-first (reverse insertion order).
    for (final obj in objects.reversed) {
      if (!obj.optimisticExists && obj.realizedExists) {
        obj.realizeDestroy();
        obj._realizedExists = false;
      }
    }
  }

  T _createObject(ObjectClass objectClass, UUID uuid) {
    return constructors[objectClass]!(this, uuid);
  }
}
