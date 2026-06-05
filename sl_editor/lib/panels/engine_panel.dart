import 'dart:async';
import 'dart:ui_web' as ui_web;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:sl_editor/client/client.dart';
import 'package:sl_editor/widgets/name_tags.dart';
import 'package:sl_engine/editor/selector.dart';
import 'package:sl_engine/editor/sl_editor.dart';
import 'package:sl_engine/input.dart';
import 'package:vector_math/vector_math.dart';
import 'package:web/web.dart' as web;

class EnginePanel extends StatefulWidget {
  const EnginePanel({super.key});

  @override
  State<EnginePanel> createState() => _EngineViewState();
}

class _EngineViewState extends State<EnginePanel> {
  final _canvasKey = GlobalKey();
  final _focusNode = FocusNode(debugLabel: 'sl-engine-focus-node');

  late final StreamSubscription _onClientStatesChangedSubscription;
  late final StreamSubscription _onEngineFocusChangedSubscription;

  @override
  void initState() {
    ui_web.platformViewRegistry.registerViewFactory('sl-engine-view', (int viewId, {Object? params}) {
      final canvas = web.HTMLCanvasElement();
      canvas.style.width = '100%';
      canvas.style.height = '100%';
      SLEditor.initSlEditorMode(canvas);
      return canvas;
    });
    _onClientStatesChangedSubscription = Client.get().onClientStatesChanged.listen(_onClientStatesChanged);
    _onEngineFocusChangedSubscription = Input.onFocusChanged.listen(_onEngineFocusChanged);
    super.initState();
  }

  @override
  void dispose() {
    _onClientStatesChangedSubscription.cancel();
    _onEngineFocusChangedSubscription.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _onClientStatesChanged(_) {
    final color = Color(Client.get().getSelfClientState().color);
    Selector.setColor(Vector4(color.r, color.g, color.b, color.a));
  }

  void _onEngineFocusChanged(bool engineHasFocus) {
    if (engineHasFocus) {
      _focusNode.requestFocus();
    } else {
      _focusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.keyW): DoNothingAndStopPropagationIntent(),
        SingleActivator(LogicalKeyboardKey.keyE): DoNothingAndStopPropagationIntent(),
        SingleActivator(LogicalKeyboardKey.keyR): DoNothingAndStopPropagationIntent(),
      },
      child: Focus(
        focusNode: _focusNode,
        skipTraversal: true,
        child: Stack(
          children: [
            Positioned.fill(
              child: HtmlElementView(
                key: _canvasKey,
                viewType: 'sl-engine-view',
              ),
            ),
            Positioned.fill(child: NameTagsWidget()),
          ],
        ),
      ),
    );
  }
}
