import 'dart:collection';

import 'package:sl_server/state_tracker.dart';
import 'package:sl_server/validated_property.dart';
import 'package:sl_shared/sl_shared.dart';
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
  final ValidatedProperty<ParentAndOrder?> parent = ValidatedProperty(
    null,
    key: 'parent',
    validator: (receiver, v) {
      // client cannot create root node
      if (v == null) return false;

      final parentAndOrder = ParentAndOrder.fromJson(v);
      if (!parentAndOrder.isValid()) return false;

      // Check if parent node exists
      final parentNode = receiver.tracker.getObjectInMemory(parentAndOrder.uuid) as Node?;
      if (parentNode == null) return false;

      // Check if same order as any siblings
      if (parentNode.children.keys.any((order) => order == parentAndOrder.order)) return false;

      return true;
    },
    setter: (receiver, property, newValue) {
      if (property.value != null) {
        final parent = receiver.tracker.getObjectInMemory(property.value!.uuid) as Node?;
        if (parent != null) {
          parent.children.remove(property.value!.order);
        }
      }
      if (newValue != null) {
        final parentAndOrder = ParentAndOrder.fromJson(newValue);
        property.value = parentAndOrder;

        final parent = receiver.tracker.getObjectInMemory(parentAndOrder.uuid) as Node;
        parent.children[parentAndOrder.order] = receiver.uuid;
      } else {
        property.value = null;
      }
    },
    fromJson: (v) => v == null ? null : ParentAndOrder.fromJson(v),
  );
  final SplayTreeMap<Fraction, UUID> children = SplayTreeMap();

  final ValidatedProperty<Vector3> lPos = ValidatedProperty(
    Vector3.zero(),
    key: 'lPos',
    validator: vector3Validator,
    setter: vector3Setter,
    toJson: vec3ToJson,
    fromJson: vec3FromJson,
  );
  final ValidatedProperty<Quaternion> lRot = ValidatedProperty(
    Quaternion.identity(),
    key: 'lRot',
    validator: quaternionValidator,
    setter: quaternionSetter,
    toJson: quatToJson,
    fromJson: quatFromJson,
  );
  final ValidatedProperty<Vector3> lScale = ValidatedProperty(
    Vector3(1.0, 1.0, 1.0),
    key: 'lScale',
    validator: vector3Validator,
    setter: vector3Setter,
    toJson: vec3ToJson,
    fromJson: vec3FromJson,
  );
  final ValidatedProperty<UUID?> asset = ValidatedProperty(
    null,
    key: 'asset',
    validator: (_, _) => true,
  );

  Node(super.tracker, super.uuid);

  @override
  ObjectClass get objectClass => 'node';
  static ObjectClass get objectClassS => 'node';

  @override
  List<ValidatedProperty> get properties => [name, parent, lPos, lRot, lScale, asset];
}
