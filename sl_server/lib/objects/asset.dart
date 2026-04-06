import 'package:sl_server/database/database.dart' as db;
import 'package:sl_server/state_tracker.dart';
import 'package:sl_server/validated_property.dart';
import 'package:sl_shared/sl_shared.dart';

class TrackedAsset extends StateTracked {
  final name = ValidatedProperty<String>(
    'New Asset',
    key: 'name',
    validator: (_, v) {
      // TODO
      return true;
    },
  );
  final parent = ValidatedProperty<UUID?>(
    null,
    key: 'parent',
    validator: (_, v) {
      // TODO
      return true;
    },
  );
  final type = ValidatedProperty<AssetType>(
    .propertiesOnly,
    key: 'type',
    validator: (_, v) {
      // TODO
      return true;
    },
  );
  final properties = ValidatedProperty<dynamic>(
    null,
    key: 'properties',
    validator: (_, v) {
      // TODO
      return true;
    },
  );
  final blobSize = ValidatedProperty<int?>(
    0,
    key: 'blobSize',
    validator: (_, v) {
      // TODO
      return true;
    },
  );

  TrackedAsset(super.tracker, super.uuid);
  TrackedAsset.fromDatabase(StateTracker tracker, db.Asset asset) : super(tracker, asset.uuid) {
    name.value = asset.name;
    parent.value = asset.parent;
    type.value = asset.type;
    properties.value = asset.properties;
    blobSize.value = asset.blobSize;
  }

  static ObjectClass get objectClass => 'asset';

  @override
  bool isValid(Delta delta) {
    if (!super.isValid(delta)) return false;
    try {
      if (!name.validate(this, delta)) return false;
      if (!parent.validate(this, delta)) return false;
      if (!type.validate(this, delta)) return false;
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void applyDelta(Delta delta) {
    name.set(this, delta);
    parent.set(this, delta);
    type.set(this, delta);
    super.applyDelta(delta);
  }
}
