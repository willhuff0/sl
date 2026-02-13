import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:sl_editor/client/client.dart';
import 'package:sl_shared/sl_shared.dart';

final _ownCursorPositionController = StreamController<CursorPosition>.broadcast();
final ownCursorPositionStream = _ownCursorPositionController.stream;

class CursorsWidget extends StatefulWidget {
  const CursorsWidget({super.key});

  @override
  State<CursorsWidget> createState() => CursorsWidgetState();
}

class CursorsWidgetState extends State<CursorsWidget> {
  late final StreamSubscription _otherCursorPositionsSubscription;
  List<(int color, CursorPosition)> _otherCursorPositions = [];

  @override
  void initState() {
    _otherCursorPositionsSubscription = otherCursorPositionStream.listen(_onOtherCursorPositionsChanged);
    super.initState();
  }

  @override
  void dispose() {
    _otherCursorPositionsSubscription.cancel();
    super.dispose();
  }

  void _onOwnCursorPositionChanged(PointerHoverEvent event) {
    _ownCursorPositionController.add(
      CursorPosition(
        panel: PanelType.engine,
        x: event.localPosition.dx,
        y: event.localPosition.dy,
      ),
    );
  }

  void _onOwnCursorLeft(_) {}

  void _onOtherCursorPositionsChanged(List<(int color, CursorPosition)> otherCursorPositions) {
    setState(() => _otherCursorPositions = otherCursorPositions);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: _onOwnCursorPositionChanged,
      onExit: _onOwnCursorLeft,
      opaque: false,
      child: Stack(
        children: _otherCursorPositions.map((entry) {
          final color = Color(entry.$1);
          final cursorPosition = entry.$2;
          return Positioned(
            left: cursorPosition.x,
            top: cursorPosition.y,
            child: Icon(
              LucideIcons.mousePointer2,
              color: color,
            ),
          );
        }).toList(),
      ),
    );
  }
}
