import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class DisableShortcuts extends StatelessWidget {
  final Widget child;

  /// Disables global keyboard shortcuts. Useful for text fields.
  const DisableShortcuts({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.keyW): DoNothingAndStopPropagationIntent(),
        SingleActivator(LogicalKeyboardKey.keyE): DoNothingAndStopPropagationIntent(),
        SingleActivator(LogicalKeyboardKey.keyR): DoNothingAndStopPropagationIntent(),
      },
      child: child,
    );
  }
}
