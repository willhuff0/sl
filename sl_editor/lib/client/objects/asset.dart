import 'dart:async';

import 'package:sl_editor/client/state_tracker.dart';
import 'package:sl_editor/client/tracked_property.dart';
import 'package:sl_shared/sl_shared.dart';

class FoldedAsset {
  final UUID uuid;
  final List<FoldedAsset> children;

  FoldedAsset({
    required this.uuid,
    required this.children,
  });
}

class TrackedAsset extends StateTracked {
  final name = TrackedProperty<String>(path: 'name', value: 'New Asset');
  final parent = TrackedProperty<UUID?>(path: 'parent', value: null);
  final type = TrackedProperty<AssetType>(
    path: 'type',
    value: .propertiesOnly,
    toJson: (value) => value.name,
    fromJson: (json) => AssetType.values.byName(json),
  );
  final properties = TrackedProperty<dynamic>(path: 'properties', value: null);
  final blobSize = TrackedProperty<int?>(path: 'blobSize', value: null);
  final isSubAsset = TrackedProperty<bool>(path: 'isSubAsset', value: false);

  var isBlobLocal = false;

  final _onChangedController = StreamController.broadcast();
  late final Stream onChanged;

  static ObjectClass get objectClass => 'asset';

  static TrackedAsset create(StateTracker tracker) {
    final node = TrackedAsset(tracker, generateUuid());
    node.createThis(objectClass);
    return node;
  }

  TrackedAsset(super.tracker, super.uuid) {
    onChanged = _onChangedController.stream;
  }

  @override
  void getDeltaFromNull(Delta builder) {
    name.getDeltaFromNullRelToObject(builder);
    parent.getDeltaFromNullRelToObject(builder);
    type.getDeltaFromNullRelToObject(builder);
    properties.getDeltaFromNullRelToObject(builder);
    blobSize.getDeltaFromNullRelToObject(builder);
    super.getDeltaFromNull(builder);
  }

  @override
  void applyDelta(Delta delta) {
    name.applyDeltaRelToObject(this, delta);
    parent.applyDeltaRelToObject(this, delta);
    type.applyDeltaRelToObject(this, delta);
    properties.applyDeltaRelToObject(this, delta);
    blobSize.applyDeltaRelToObject(this, delta);
    super.applyDelta(delta);
  }
}
