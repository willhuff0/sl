import 'package:sl_engine/gl/mesh.dart';
import 'package:sl_engine/node.dart';
import 'package:sl_engine/utils/renderer.dart';

class MeshComponent extends Component {
  final Mesh mesh;

  MeshComponent({required this.mesh});

  @override
  void onEnable() {
    Renderer.addMeshToNode(node, mesh);
  }

  @override
  void onDisable() {
    Renderer.removeMeshFromNode(node, mesh);
  }
}
