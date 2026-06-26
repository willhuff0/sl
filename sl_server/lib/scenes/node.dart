import 'dart:collection';

import 'package:sl_server/state_tracker.dart';
import 'package:sl_server/validated_property.dart';
import 'package:sl_shared/sl_shared.dart';
import 'package:vector_math/vector_math.dart';

class Node extends StateTracked {
  final ValidatedProperty<String> name = ValidatedProperty(NodeSchema.name);
  final ValidatedProperty<ParentAndOrder?> parent = ValidatedProperty(
    NodeSchema.parent,
    receiverValidator: (receiver, v) {
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
  );
  final SplayTreeMap<Fraction, UUID> children = SplayTreeMap();

  final ValidatedProperty<Vector3> lPos = ValidatedProperty(NodeSchema.lPos, setter: _vector3Setter);
  final ValidatedProperty<Quaternion> lRot = ValidatedProperty(NodeSchema.lRot, setter: _quaternionSetter);
  final ValidatedProperty<Vector3> lScale = ValidatedProperty(NodeSchema.lScale, setter: _vector3Setter);
  final ValidatedProperty<UUID?> asset = ValidatedProperty(NodeSchema.asset);

  Node(super.tracker, super.uuid);

  @override
  ObjectClass get objectClass => NodeSchema.objectClass;
  static ObjectClass get objectClassS => NodeSchema.objectClass;

  @override
  List<ValidatedProperty> get properties => [name, parent, lPos, lRot, lScale, asset];
}

void _vector3Setter(_, ValidatedProperty o, dynamic v) {
  o.value = Vector3(v[0].toDouble(), v[1].toDouble(), v[2].toDouble());
}

void _quaternionSetter(_, ValidatedProperty o, dynamic v) {
  o.value = Quaternion(v[0].toDouble(), v[1].toDouble(), v[2].toDouble(), v[3].toDouble());
}
