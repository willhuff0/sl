import 'package:vector_math/vector_math.dart';

// Vector3 recToVec3((double, double, double) record) => Vector3(record.$1, record.$2, record.$3);
// Quaternion recToQuat((double, double, double, double) record) => Quaternion(record.$1, record.$2, record.$3, record.$4);

Vector3 vec3FromJson(dynamic json) => Vector3(json[0], json[1], json[2]);
Quaternion quatFromJson(dynamic json) => Quaternion(json[0], json[1], json[2], json[3]);

List<double> vec3ToJson(Vector3 value) => value.storage;
List<double> quatToJson(Quaternion value) => value.storage;

// List<double> recToVec3Json((double, double, double) record) => [record.$1, record.$2, record.$3];
// List<double> recToQuatJson((double, double, double, double) record) => [record.$1, record.$2, record.$3, record.$4];

// (double, double, double) vec3JsonToRec(dynamic json) => (json[0], json[1], json[2]);
// (double, double, double, double) quatJsonToRec(dynamic json) => (json[0], json[1], json[2], json[3]);
