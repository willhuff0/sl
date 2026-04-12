import 'package:sl_editor/client/objects/node.dart';
import 'package:sl_editor/client/state_tracker.dart';
import 'package:sl_engine/editor/selector.dart';
import 'package:sl_engine/editor/sl_editor.dart';
import 'package:sl_shared/sl_shared.dart';
import 'package:vector_math/vector_math.dart';

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
      selection: Selector.getSelected().map((node) => Node.getTrackerForEngineNode(node).uuid).toSet(),
    );
  }

  static void setRemoteViewPositions(StateTracker tracker, Map<int, (Vector4, ViewPosition)> viewPositions) {
    Selector.setRemoteSelected(
      viewPositions.map(
        (clientId, value) => MapEntry(clientId, (
          value.$1,
          value.$2.selection.map((uuid) => (tracker.getObject(uuid) as Node).engineNode).toSet(),
        )),
      ),
    );
    // TODO: set remote cameras
  }
}
