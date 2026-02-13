import 'package:sl_editor/client/state_tracker.dart';
import 'package:sl_shared/sl_shared.dart';

class Node extends StateTracked {
  final TrackedProperty<UUID?> parent = TrackedProperty('parent', null);
  final TrackedProperty<double> indexInParent = TrackedProperty('index', 0.0);

  static Node create() {
    final node = Node._(generateUuid());
    node.createThis('node');
    return node;
  }

  Node._(super.uuid);

  @override
  void getDeltaFromNull(Delta builder) {
    super.getDeltaFromNull(builder);
    parent.getDeltaFromNullRelToObject(builder);
    indexInParent.getDeltaFromNullRelToObject(builder);
  }

  @override
  void applyDelta(Delta delta) {
    super.applyDelta(delta);
    parent.applyDeltaRelToObject(delta);
    indexInParent.applyDeltaRelToObject(delta);
  }
}

void test() {
  Node node = Node.create();
  node.modifyLocal((builder) {
    node.parent.set(builder, 'test');
  });
}
