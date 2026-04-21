import 'package:sl_editor/client/client.dart';
import 'package:sl_editor/client/scenes/node.dart';
import 'package:sl_editor/client/scenes/scene_system.dart';
import 'package:sl_editor/client/state_tracker.dart';
import 'package:sl_engine/editor/avatars.dart';
import 'package:sl_engine/editor/selector.dart';
import 'package:sl_engine/editor/sl_editor.dart';
import 'package:sl_shared/sl_shared.dart';
import 'package:vector_math/vector_math.dart';

Vector3 _tupleToVec3((double, double, double) tuple) {
  return Vector3(tuple.$1, tuple.$2, tuple.$3);
}

Quaternion _tupleToQuaternion((double, double, double, double) tuple) {
  return Quaternion(tuple.$1, tuple.$2, tuple.$3, tuple.$4);
}

class ViewManager {
  static (Vector3, Quaternion, double)? _lastViewPosition;
  static var _selectionChanged = false;

  static void init() {
    Selector.onSelectionChanged.listen((_) => _selectionChanged = true);
  }

  static bool hasViewChangedAndUpdate() {
    final viewPosition = SLEditor.camera?.getViewPosition();
    if (viewPosition == null) return false;

    if (_selectionChanged || viewPosition != _lastViewPosition) {
      _lastViewPosition = viewPosition;
      _selectionChanged = false;
      return true;
    }
    return false;
  }

  static ViewPosition getViewPosition() {
    return ViewPosition(
      position: (_lastViewPosition!.$1.x, _lastViewPosition!.$1.y, _lastViewPosition!.$1.z),
      orientation: (_lastViewPosition!.$2.x, _lastViewPosition!.$2.y, _lastViewPosition!.$2.z, _lastViewPosition!.$2.w),
      fov: _lastViewPosition!.$3,
      cursor: (0.0, 0.0),
      selection: Selector.getSelected()
          .map((node) => Client.get().sceneSystem.getTrackedFromEngineNode(node).uuid)
          .toSet(),
    );
  }

  static void setRemoteViewPositions(
    StateTracker<SceneStateTracked> tracker,
    Map<int, (Vector4, ViewPosition)> viewPositions,
  ) {
    Selector.setRemoteSelected(
      viewPositions.map(
        (clientId, value) => MapEntry(clientId, (
          value.$1,
          value.$2.selection.map((uuid) => (tracker.getObject(uuid) as Node).engineNode).toSet(),
        )),
      ),
    );
    Avatars.setRemoteViews(
      viewPositions.map(
        (clientId, value) => MapEntry(
          clientId,
          (_tupleToVec3(value.$2.position), _tupleToQuaternion(value.$2.orientation), value.$1),
        ),
      ),
    );
  }
}
