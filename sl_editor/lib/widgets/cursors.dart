import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

final _ownCursorPositionController = StreamController<(double, double)?>.broadcast();
final ownCursorPositionStream = _ownCursorPositionController.stream;

class CursorsWidget extends StatefulWidget {
  final Widget? child;

  const CursorsWidget({super.key, this.child});

  @override
  State<CursorsWidget> createState() => CursorsWidgetState();
}

class CursorsWidgetState extends State<CursorsWidget> {
  void _onOwnCursorPositionChanged(PointerHoverEvent event) {
    _ownCursorPositionController.add((event.localPosition.dx, event.localPosition.dy));
  }

  void _onOwnCursorLeft(_) {
    _ownCursorPositionController.add(null);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: _onOwnCursorPositionChanged,
      onExit: _onOwnCursorLeft,
      opaque: false,
      child: widget.child,
    );
  }
}
