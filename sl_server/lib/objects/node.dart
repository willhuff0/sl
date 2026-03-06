import 'dart:collection';

import 'package:sl_server/state_tracker.dart';
import 'package:sl_server/validated_property.dart';
import 'package:sl_shared/sl_shared.dart';
import 'package:uuid/uuid.dart';
import 'package:vector_math/vector_math.dart';

class Node extends StateTracked {
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
  final ValidatedProperty<UUID?> parent = ValidatedProperty(
    null,
    key: 'parent',
    validator: (receiver, v) {
      if (v is! UUID?) return false;
      if (v == null) return true;
      if (!Uuid.isValidUUID(fromString: v)) return false;

      final parent = receiver.tracker.getObject(v);
      if (parent == null || parent is! Node?) return false;
      // TODO: check for cycles

      return true;
    },
    setter: (receiver, property, newValue) {
      if (property.value != null) {
        final parent = receiver.tracker.getObject(property.value!) as Node?;
        if (parent != null) {
          parent.children.remove(receiver.uuid);
        }
      }
      property.value = newValue;
      if (newValue != null) {
        final parent = receiver.tracker.getObject(newValue) as Node;
        parent.children.add(receiver.uuid);
      }
    },
  );
  final ValidatedProperty<Fraction> orderInParent = ValidatedProperty(
    Fraction.zero,
    key: 'order',
    validator: (receiver, v) {
      if (v is! Fraction) return false;
      if (!v.isValid()) return false;

      // Check if equal to any sibling
      final node = receiver as Node;
      if (node.parent.value != null) {
        final parent = receiver.tracker.getObject(node.parent.value!) as Node;
        if (parent.children.entries.any((entry) => entry.value != node.uuid && entry.key == v)) return false;
      }

      return true;
    },
    setter: (_, property, newValue) {
      property.value = (newValue as Fraction).reduced();
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
    if (!name.validate(this, delta)) return false;
    if (!parent.validate(this, delta)) return false;
    if (!lPos.validate(this, delta)) return false;
    if (!lRot.validate(this, delta)) return false;
    if (!lScale.validate(this, delta)) return false;
    return true;
  }

  @override
  void applyDelta(Delta delta) {
    name.set(this, delta);
    parent.set(this, delta);
    lPos.set(this, delta);
    lRot.set(this, delta);
    lScale.set(this, delta);
  }
}
