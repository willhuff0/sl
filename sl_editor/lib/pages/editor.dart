import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:sl_editor/client/client.dart';
import 'package:sl_editor/panels/asset_panel.dart';
import 'package:sl_editor/panels/console_panel.dart';
import 'package:sl_editor/panels/engine_panel.dart';
import 'package:sl_editor/panels/node_graph_panel.dart';
import 'package:sl_editor/panels/properties_panel.dart';
import 'package:sl_editor/widgets/avatars.dart';
import 'package:sl_editor/widgets/cursors.dart';
import 'package:sl_editor/widgets/window_title_bar.dart';

class EditorClientLoader extends StatefulWidget {
  const EditorClientLoader({super.key});

  @override
  State<EditorClientLoader> createState() => _EditorClientLoaderState();
}

class _EditorClientLoaderState extends State<EditorClientLoader> {
  Client? _client;

  @override
  void initState() {
    _load();
    super.initState();
  }

  @override
  void dispose() {
    _client?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    const room = 'test-room';
    _client = await Client.connect(
      projectId: room,
      serverUri: Uri.parse('http://localhost:8080'),
    );
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return _client == null
        ? Column(
            crossAxisAlignment: .center,
            mainAxisAlignment: .center,
            children: [
              Text(
                'Connecting...',
                style: TextStyle(
                  color: ShadTheme.of(context).colorScheme.foreground.withValues(alpha: 0.6),
                ),
              ),
              SizedBox(height: 8.0),
              SizedBox(
                width: 100.0,
                height: 4.0,
                child: ShadProgress(),
              ),
            ],
          )
        : EditorPage();
  }
}

class EditorPage extends StatelessWidget {
  const EditorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Column(
            children: [
              WindowTitleBar(
                height: 38.0,
                leading: [
                  ShadMenubar(
                    border: ShadBorder(
                      left: ShadBorderSide.none,
                      top: ShadBorderSide.none,
                      bottom: ShadBorderSide.none,
                      right: ShadBorderSide(
                        color: ShadTheme.of(context).colorScheme.border,
                        width: 2.0,
                        strokeAlign: BorderSide.strokeAlignOutside,
                      ),
                    ),
                    selectOnHover: false,
                    items: [
                      Padding(
                        padding: const EdgeInsets.only(left: 14.0, right: 8.0),
                        child: Text(
                          'SL',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      ShadMenubarItem(
                        items: [
                          ShadContextMenuItem(
                            child: Text('File'),
                            onPressed: () {},
                          ),
                        ],
                        child: Text('File'),
                      ),
                      ShadMenubarItem(
                        items: [
                          ShadContextMenuItem(
                            child: Text('File'),
                            onPressed: () {},
                          ),
                        ],
                        child: Text('Edit'),
                      ),
                      ShadMenubarItem(
                        items: [
                          ShadContextMenuItem(
                            child: Text('File'),
                            onPressed: () {},
                          ),
                        ],
                        child: Text('View'),
                      ),
                    ],
                  ),
                ],
                trailing: [
                  AvatarsWidget(),
                  _ShareButton(),
                  _AccountButton(),
                ],
              ),
              ShadSeparator.horizontal(
                margin: EdgeInsets.zero,
              ),
              Expanded(
                child: ShadResizablePanelGroup(
                  axis: Axis.horizontal,
                  children: [
                    ShadResizablePanel(
                      id: 0,
                      defaultSize: 0.175,
                      child: ShadResizablePanelGroup(
                        axis: Axis.vertical,
                        children: [
                          ShadResizablePanel(
                            id: 'node-graph',
                            defaultSize: 0.5,
                            child: NodeGraphPanel(root: null),
                          ),
                          ShadResizablePanel(
                            id: 'asset',
                            defaultSize: 0.5,
                            child: AssetPanel(),
                          ),
                        ],
                      ),
                    ),
                    ShadResizablePanel(
                      id: 1,
                      defaultSize: 0.625,
                      child: ShadResizablePanelGroup(
                        axis: Axis.vertical,
                        children: [
                          ShadResizablePanel(
                            id: 'engine',
                            defaultSize: 0.652,
                            child: EnginePanel(),
                          ),
                          ShadResizablePanel(
                            id: 'console',
                            defaultSize: 0.375,
                            child: ConsolePanel(),
                          ),
                        ],
                      ),
                    ),
                    ShadResizablePanel(
                      id: 2,
                      defaultSize: 0.2,
                      child: ShadResizablePanelGroup(
                        axis: Axis.vertical,
                        children: [
                          ShadResizablePanel(
                            id: 'properties',
                            defaultSize: 1.0,
                            child: PropertiesPanel(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned.fill(child: CursorsWidget()),
      ],
    );
  }
}

class _ShareButton extends StatelessWidget {
  const _ShareButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 4.0),
      child: ShadIconButton.ghost(
        decoration: ShadDecoration(
          shape: BoxShape.circle,
        ),
        onPressed: () async {},
        icon: Icon(LucideIcons.users, size: 14.0),
      ),
    );
  }
}

class _AccountButton extends StatelessWidget {
  const _AccountButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 4.0),
      child: ShadIconButton.ghost(
        decoration: ShadDecoration(
          shape: BoxShape.circle,
        ),
        onPressed: () {},
        icon: ShadAvatar(
          null,
          placeholder: Text('W'),
        ),
      ),
    );
  }
}
