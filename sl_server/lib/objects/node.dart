import 'package:sl_server/state_tracker.dart';
import 'package:sl_server/validator.dart';
import 'package:sl_shared/sl_shared.dart';
import 'package:uuid/uuid.dart';
import 'package:vector_math/vector_math.dart';

class Node extends StateTracked {
  Val<String> name = Val(
    'New Node',
    key: 'name',
    validator: (v) {
      if (v is! String) return false;
      if (v != v.trim()) return false;
      if (v.isEmpty || v.length > 128) return false;
      return true;
    },
  );
  Val<List<UUID>> children = Val(
    [],
    key: 'children',
    validator: (v) {
      if (v is! List<dynamic>) return false;
      if (v.isEmpty) return true;
      for (final c in v) {
        if (!Uuid.isValidUUID(fromString: c)) return false;
        // TODO: check for cycles, multiple parents
      }
      return true;
    },
  );
  Node? parent;

  Val<Vector3> lPos = Val(
    Vector3.zero(),
    key: 'lPos',
    validator: vector3Validator,
    setter: vector3Setter,
  );
  Val<Quaternion> lRot = Val(
    Quaternion.identity(),
    key: 'lRot',
    validator: quaternionValidator,
    setter: quaternionSetter,
  );
  Val<Vector3> lScale = Val(
    Vector3(1.0, 1.0, 1.0),
    key: 'lScale',
    validator: vector3Validator,
    setter: vector3Setter,
  );

  Node(super.uuid);

  static ObjectClass get objectClass => 'node';

  @override
  bool isValid(Delta delta) {
    if (!name.validate(delta)) return false;
    if (!children.validate(delta)) return false;
    if (!lPos.validate(delta)) return false;
    if (!lRot.validate(delta)) return false;
    if (!lScale.validate(delta)) return false;
    return true;
  }

  @override
  void applyDelta(Delta delta) {
    name.set(delta);
    children.set(delta);
    lPos.set(delta);
    lRot.set(delta);
    lScale.set(delta);
  }
}
