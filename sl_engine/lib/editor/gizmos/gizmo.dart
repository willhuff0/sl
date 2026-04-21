import 'package:sl_engine/node.dart';
import 'package:sl_engine/gl/shader.dart';
import 'package:sl_engine/editor/fly_camera.dart';
import 'package:sl_engine/utils/clicker.dart';

abstract class Gizmo {
  void init(Node root);
  List<Node> getHandles();
  Node? onMouseDown(int x, int y, Node selectedNode, FlyCamera camera, Clicker clicker);
  void onMouseMove(int x, int y, Node selectedNode, FlyCamera camera);
  void onMouseUp();
  void draw(Shader flatShader, double screenProportion);
}
