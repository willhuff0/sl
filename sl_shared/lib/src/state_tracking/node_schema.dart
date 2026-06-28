import 'package:sl_shared/sl_shared.dart';
import 'package:vector_math/vector_math.dart';

/// Single source of truth for a node's tracked properties, shared by the server and client.
/// Each side wraps these in its own property type (validating vs. optimistic/effecting), but
/// the key, codec, default, and value validation come from here.
abstract class NodeSchema {
  static const ObjectClass objectClass = 'node';

  static final PropertySchema<String> name = PropertySchema<String>(
    key: 'name',
    createDefault: () => 'New Node',
    validateValue: (value) {
      if (value is! String) return false;
      if (value != value.trim()) return false;
      if (value.isEmpty || value.length > 128) return false;
      return true;
    },
  );

  // `toJson` keeps the encoded delta value JSON-primitive (a Map) even in memory, so the client can
  // decode it when replaying its own pending changes. Receiver-dependent validation (parent must
  // exist, order must be free) lives on the server.
  static final PropertySchema<ParentAndOrder?> parent = PropertySchema<ParentAndOrder?>(
    key: 'parent',
    createDefault: () => null,
    toJson: (value) => value?.toJson(),
    fromJson: (json) => json == null ? null : ParentAndOrder.fromJson(json),
    // ParentAndOrder/Fraction have no value `==`, so define equality explicitly to avoid spurious
    // reparent effects in the client's diff-based reconciliation.
    equality: (a, b) {
      if (a == null || b == null) return a == b;
      return a.uuid == b.uuid && a.order.compareTo(b.order) == 0;
    },
  );

  static final PropertySchema<Vector3> lPos = PropertySchema<Vector3>(
    key: 'lPos',
    createDefault: () => Vector3.zero(),
    toJson: _vec3ToJson,
    fromJson: _vec3FromJson,
    validateValue: _isVector3Json,
  );

  static final PropertySchema<Quaternion> lRot = PropertySchema<Quaternion>(
    key: 'lRot',
    createDefault: () => Quaternion.identity(),
    toJson: _quatToJson,
    fromJson: _quatFromJson,
    validateValue: _isQuaternionJson,
  );

  static final PropertySchema<Vector3> lScale = PropertySchema<Vector3>(
    key: 'lScale',
    createDefault: () => Vector3(1.0, 1.0, 1.0),
    toJson: _vec3ToJson,
    fromJson: _vec3FromJson,
    validateValue: _isVector3Json,
  );

  static final PropertySchema<UUID?> asset = PropertySchema<UUID?>(
    key: 'asset',
    createDefault: () => null,
  );
}

Vector3 _vec3FromJson(dynamic json) => Vector3(json[0], json[1], json[2]);
Quaternion _quatFromJson(dynamic json) => Quaternion(json[0], json[1], json[2], json[3]);

List<double> _vec3ToJson(Vector3 value) => value.storage;
List<double> _quatToJson(Quaternion value) => value.storage;

bool _isVector3Json(dynamic value) {
  if (value is! List<dynamic>) return false;
  if (value.length != 3) return false;
  if (value[0] is! num) return false;
  if (value[1] is! num) return false;
  if (value[2] is! num) return false;
  return true;
}

bool _isQuaternionJson(dynamic value) {
  if (value is! List<dynamic>) return false;
  if (value.length != 4) return false;
  if (value[0] is! num) return false;
  if (value[1] is! num) return false;
  if (value[2] is! num) return false;
  if (value[3] is! num) return false;
  return true;
}
