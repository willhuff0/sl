import 'package:sl_engine/gl/mesh.dart';
import 'package:sl_engine/node.dart';
import 'package:sl_engine/utils/renderer.dart';

class MeshComponent extends Component {
  final Material material;
  final Mesh mesh;

  MeshComponent({
    required this.material,
    required this.mesh,
  });

  @override
  void onEnable() {
    Renderer.addNode(node, material, mesh);
  }

  @override
  void onDisable() {
    Renderer.removeNode(node, material, mesh);
  }
}
