import 'package:flutter/widgets.dart';

class WindowTitleBar extends StatelessWidget {
  final double height;
  final List<Widget> leading;
  final List<Widget> trailing;

  const WindowTitleBar({super.key, this.height = 40.0, this.leading = const [], this.trailing = const []});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            ...leading,
            Expanded(child: Container()),
            ...trailing,
            SizedBox(width: 2.0),
          ],
        ),
      ),
    );
  }
}
