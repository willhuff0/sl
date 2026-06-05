import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:sl_engine/editor/selector.dart';

class GizmoButtonsWidget extends StatefulWidget {
  const GizmoButtonsWidget({super.key});

  @override
  State<GizmoButtonsWidget> createState() => _GizmoButtonsWidgetState();
}

class _GizmoButtonsWidgetState extends State<GizmoButtonsWidget> {
  late final StreamSubscription _onGizmoChangedSubscription;
  var _activeGizmoType = GizmoType.translation;

  @override
  void initState() {
    _onGizmoChangedSubscription = Selector.onGizmoChanged.listen(_onGizmoChanged);
    super.initState();
  }

  @override
  void dispose() {
    _onGizmoChangedSubscription.cancel();
    super.dispose();
  }

  void _onGizmoChanged(GizmoType gizmoType) {
    setState(() {
      _activeGizmoType = gizmoType;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: .center,
      children: [
        ShadButton.ghost(
          width: 40.0,
          height: 40.0,
          size: .sm,
          backgroundColor: _activeGizmoType == .translation
              ? ShadTheme.of(context).colorScheme.accent.withValues(alpha: 0.5)
              : null,
          child: Icon(LucideIcons.move3d),
          onPressed: () {
            Selector.setGizmoType(.translation);
          },
        ),
        ShadButton.ghost(
          width: 40.0,
          height: 40.0,
          size: .sm,
          backgroundColor: _activeGizmoType == .rotation
              ? ShadTheme.of(context).colorScheme.accent.withValues(alpha: 0.5)
              : null,
          child: Icon(LucideIcons.rotate3d),
          onPressed: () {
            Selector.setGizmoType(.rotation);
          },
        ),
        ShadButton.ghost(
          width: 40.0,
          height: 40.0,
          size: .sm,
          backgroundColor: _activeGizmoType == .scale
              ? ShadTheme.of(context).colorScheme.accent.withValues(alpha: 0.5)
              : null,
          child: Icon(LucideIcons.scale3d),
          onPressed: () {
            Selector.setGizmoType(.scale);
          },
        ),
      ],
    );
  }
}
