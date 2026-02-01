import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:sl_engine/sl_engine.dart' as engine;
import 'package:web/web.dart' as web;

class EnginePanel extends StatefulWidget {
  const EnginePanel({super.key});

  @override
  State<EnginePanel> createState() => _EngineViewState();
}

class _EngineViewState extends State<EnginePanel> {
  @override
  void initState() {
    ui_web.platformViewRegistry.registerViewFactory('sl-engine-view', (int viewId, {Object? params}) {
      final canvas = web.HTMLCanvasElement();
      engine.initialize(canvas);
      return canvas;
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: 'sl-engine-view');
  }
}
