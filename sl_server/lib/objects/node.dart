import 'dart:collection';

import 'package:sl_server/asset.dart';
import 'package:sl_server/state_tracker.dart';
import 'package:sl_server/validated_property.dart';
import 'package:sl_shared/sl_shared.dart';
import 'package:vector_math/vector_math.dart';

class Node extends StateTracked implements AssetLoadable {
  final ValidatedProperty<String> name = ValidatedProperty(
    'New Node',
    key: 'name',
    validator: (_, v) {
      if (v is! String) return false;
      if (v != v.trim()) return false;
      if (v.isEmpty || v.length > 128) return false;
      return true;
    },
  );
  final ValidatedProperty<ParentAndOrder?> parent = ValidatedProperty(
    null,
    key: 'parent',
    validator: (receiver, v) {
      if (v == null) return true;

      final parentAndOrder = ParentAndOrder.fromJson(v);
      if (!parentAndOrder.isValid()) return false;

      // Check if parent node exists
      final parentNode = receiver.tracker.getObject(parentAndOrder.uuid) as Node?;
      if (parentNode == null) return false;

      // Check if same order as any siblings
      if (parentNode.children.keys.any((order) => order == parentAndOrder.order)) return false;

      return true;
    },
    setter: (receiver, property, newValue) {
      if (property.value != null) {
        final parent = receiver.tracker.getObject(property.value!.uuid) as Node?;
        if (parent != null) {
          parent.children.remove(property.value!.order);
        }
      }
      if (newValue != null) {
        final parentAndOrder = ParentAndOrder.fromJson(newValue);
        property.value = parentAndOrder;

        final parent = receiver.tracker.getObject(newValue) as Node;
        parent.children[parentAndOrder.order] = receiver.uuid;
      } else {
        property.value = null;
      }
    },
  );
  final SplayTreeMap<Fraction, UUID> children = SplayTreeMap();

  final ValidatedProperty<Vector3> lPos = ValidatedProperty(
    Vector3.zero(),
    key: 'lPos',
    validator: vector3Validator,
    setter: vector3Setter,
  );
  final ValidatedProperty<Quaternion> lRot = ValidatedProperty(
    Quaternion.identity(),
    key: 'lRot',
    validator: quaternionValidator,
    setter: quaternionSetter,
  );
  final ValidatedProperty<Vector3> lScale = ValidatedProperty(
    Vector3(1.0, 1.0, 1.0),
    key: 'lScale',
    validator: vector3Validator,
    setter: vector3Setter,
  );

  Node(super.tracker, super.uuid);

  static ObjectClass get objectClass => 'node';

  @override
  bool isValid(Delta delta) {
    if (!super.isValid(delta)) return false;
    try {
      if (!name.validate(this, delta)) return false;
      if (!parent.validate(this, delta)) return false;
      if (!lPos.validate(this, delta)) return false;
      if (!lRot.validate(this, delta)) return false;
      if (!lScale.validate(this, delta)) return false;
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void applyDelta(Delta delta) {
    name.set(this, delta);
    parent.set(this, delta);
    lPos.set(this, delta);
    lRot.set(this, delta);
    lScale.set(this, delta);
    super.applyDelta(delta);
  }
}
