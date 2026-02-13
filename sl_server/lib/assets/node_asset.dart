import 'package:sl_server/assets/asset.dart';
import 'package:sl_shared/sl_shared.dart';
import 'package:vector_math/vector_math.dart';

abstract class ComponentAsset extends Asset {
  ComponentAsset({
    required super.uuid,
    required super.path,
  });
}

class NodeAsset extends Asset {
  final String name;
  final UUID? parent;
  final Matrix4 transform;
  final List<UUID> components;

  NodeAsset({
    required super.uuid,
    required super.path,
    required this.name,
    required this.parent,
    required this.transform,
    required this.components,
  });
}
