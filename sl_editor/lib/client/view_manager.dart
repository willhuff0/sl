import 'package:sl_editor/client/objects/node.dart';
import 'package:sl_editor/client/state_tracker.dart';
import 'package:sl_engine/editor_utils/selector.dart';
import 'package:sl_engine/sl_engine.dart';
import 'package:sl_shared/sl_shared.dart';
import 'package:vector_math/vector_math.dart';

class ViewManager {
  static (Vector3, Quaternion, double)? _lastViewPosition;

  static bool hasViewChangedAndUpdate() {
    final viewPosition = getEditorCameraView();
    if (viewPosition != _lastViewPosition) {
      _lastViewPosition = viewPosition;
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
      selection: Selector.getSelected().map((node) => Node.getTrackerForEngineNode(node).uuid).toSet(),
    );
  }

  static void setRemoteViewPositions(Map<int, (Vector4, ViewPosition)> viewPositions) {
    Selector.setRemoteSelected(
      viewPositions.map(
        (clientId, value) => MapEntry(clientId, (
          value.$1,
          value.$2.selection.map((uuid) => (StateTracker.getObject(uuid) as Node).engineNode).toSet(),
        )),
      ),
    );
    // TODO: set remote cameras
  }
}
