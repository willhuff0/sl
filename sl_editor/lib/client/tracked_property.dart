import 'dart:async';

import 'package:sl_editor/client/state_tracker.dart';
import 'package:sl_shared/sl_shared.dart';

/// A client-side tracked property in the rebase reconciliation model. It holds three layers:
///
/// - [_confirmed]: the last value the server acknowledged (authoritative).
/// - [_optimistic]: the displayed value, recomputed as confirmed + replay of pending local changes.
/// - [_realized]: the value most recently pushed into the engine via [reconcile].
///
/// Effects are no longer fired inline on mutation. Instead [flushEffect] diffs [_optimistic] against
/// [_realized] and runs [reconcile] only on a real change, which makes effects idempotent and frees
/// them from depending on the (possibly stale) current tracked value.
class TrackedProperty<T> {
  final PropertySchema<T> schema;

  T _confirmed;
  T _optimistic;
  T _realized;

  /// Total, idempotent transition pushed into the engine: reconcile from the realized value to the
  /// new optimistic value. Both endpoints always reflect real engine state, so structural effects
  /// (reparent, asset load) never read a stale tracked value.
  final void Function(StateTracked self, T from, T to)? reconcile;

  final _onChangedController = StreamController<T>.broadcast();
  late final Stream<T> onChanged;

  TrackedProperty(
    this.schema, {
    this.reconcile,
  }) : _confirmed = schema.createDefault(),
       _optimistic = schema.createDefault(),
       _realized = schema.createDefault() {
    onChanged = _onChangedController.stream;
  }

  String get key => schema.key;

  /// The displayed (optimistic) value. UI and engine read this.
  T get value => _optimistic;

  /// The last server-acknowledged value.
  T get confirmedValue => _confirmed;

  // --- confirmed layer -------------------------------------------------------------------------

  void applyConfirmed(Delta delta) {
    if (!delta.containsKey(key)) return;
    _confirmed = schema.decode(delta[key]);
  }

  /// Used when bootstrapping a freshly-created object into a layer where existence is implied by the
  /// presence of an object class rather than an explicit value in the delta.
  void setConfirmed(T value) => _confirmed = value;

  // --- optimistic layer ------------------------------------------------------------------------

  void resetOptimisticToConfirmed() => _optimistic = _confirmed;

  void setOptimistic(T value) => _optimistic = value;

  void applyOptimistic(Delta delta) {
    if (!delta.containsKey(key)) return;
    _optimistic = schema.decode(delta[key]);
  }

  // --- local edit ------------------------------------------------------------------------------

  /// Stages a local change into [builder]. Does not mutate any layer directly; the optimistic value
  /// is produced by the subsequent recompute. Returns whether anything was written.
  bool stage(Delta builder, T newValue) {
    if (schema.equals(_optimistic, newValue)) return false;
    builder[key] = schema.encode(newValue);
    return true;
  }

  /// Encodes the current optimistic value into a create delta. Used when serializing a brand-new
  /// object from nothing.
  void stageFromNull(Delta builder) {
    builder[key] = schema.encode(_optimistic);
  }

  // --- effect diffing --------------------------------------------------------------------------

  /// Pushes the optimistic value into the engine if it differs from what is currently realized.
  void flushEffect(StateTracked self) {
    if (schema.equals(_optimistic, _realized)) return;
    final from = _realized;
    _realized = _optimistic;
    reconcile?.call(self, from, _optimistic);
    _onChangedController.add(_optimistic);
  }

  /// Marks the realized value as matching the optimistic value without running [reconcile]. Used by
  /// object lifecycle transitions that realize/destroy the whole object in one step.
  void markRealized() => _realized = _optimistic;
}
