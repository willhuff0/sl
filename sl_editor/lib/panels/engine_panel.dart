import 'dart:async';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:sl_editor/client/client.dart';
import 'package:sl_engine/editor/selector.dart';
import 'package:sl_engine/editor/sl_editor.dart';
import 'package:vector_math/vector_math.dart';
import 'package:web/web.dart' as web;

class EnginePanel extends StatefulWidget {
  const EnginePanel({super.key});

  @override
  State<EnginePanel> createState() => _EngineViewState();
}

class _EngineViewState extends State<EnginePanel> {
  final _canvasKey = GlobalKey();

  late final StreamSubscription _onClientStatesChangedSubscription;

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
    super.initState();
  }

  @override
  void dispose() {
    _onClientStatesChangedSubscription.cancel();
    super.dispose();
  }

  void _onClientStatesChanged(_) {
    final color = Color(Client.get().getSelfClientState().color);
    Selector.setColor(Vector4(color.r, color.g, color.b, color.a));
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(
      key: _canvasKey,
      viewType: 'sl-engine-view',
    );
  }
}
