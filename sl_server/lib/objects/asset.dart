import 'dart:convert';

import 'package:sl_shared/src/database/database.dart' as db;
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
      // Only modified by PtpAssetBlobStart
      return false;
    },
  );
  final isSubAsset = ValidatedProperty<bool>(
    false,
    key: 'isSubAsset',
    validator: (_, v) {
      return false;
    },
  );

  TrackedAsset(super.tracker, super.uuid);
  TrackedAsset.fromDatabase(StateTracker tracker, db.Asset asset, bool isSubAsset) : super(tracker, asset.uuid) {
    name.value = asset.name;
    parent.value = asset.parent;
    type.value = asset.type;
    properties.value = asset.properties == null ? null : jsonDecode(asset.properties!);
    blobSize.value = asset.blobSize;
    this.isSubAsset.value = isSubAsset;
  }

  @override
  ObjectClass get objectClass => 'asset';
  static ObjectClass get objectClassS => 'asset';

  @override
  bool isValid(Delta delta) {
    if (!super.isValid(delta)) return false;
    try {
      if (!name.validate(this, delta)) return false;
      if (!parent.validate(this, delta)) return false;
      if (!type.validate(this, delta)) return false;
      if (!properties.validate(this, delta)) return false;
      if (!blobSize.validate(this, delta)) return false;
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
    properties.set(this, delta);
    blobSize.set(this, delta);
    super.applyDelta(delta);
  }

  @override
  void getDeltaFromNull(Delta builder) {
    name.getDeltaFromNull(builder);
    parent.getDeltaFromNull(builder);
    type.getDeltaFromNull(builder);
    properties.getDeltaFromNull(builder);
    blobSize.getDeltaFromNull(builder);
    super.getDeltaFromNull(builder);
  }
}
