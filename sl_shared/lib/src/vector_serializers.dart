import 'package:vector_math/vector_math.dart';

Vector3 recToVec3((double, double, double) record) => Vector3(record.$1, record.$2, record.$3);
Quaternion recToQuat((double, double, double, double) record) => Quaternion(record.$1, record.$2, record.$3, record.$4);
