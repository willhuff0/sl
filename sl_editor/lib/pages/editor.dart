import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:sl_editor/data.dart';
import 'package:sl_editor/widgets/panels/console_panel.dart';
import 'package:sl_editor/widgets/panels/engine_panel.dart';
import 'package:sl_editor/widgets/panels/node_graph_panel.dart';
import 'package:sl_editor/widgets/window_title_bar.dart';

import '../widgets/panels/asset_panel.dart';

class EditorPage extends StatelessWidget {
  const EditorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        WindowTitleBar(
          height: 48.0,
          leading: [
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: ShadMenubar(
                items: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text('SL'),
                  ),
                  ShadMenubarItem(
                    items: [],
                    child: Text('File'),
                  ),
                  ShadMenubarItem(
                    items: [],
                    child: Text('Edit'),
                  ),
                  ShadMenubarItem(
                    items: [],
                    child: Text('View'),
                  ),
                ],
              ),
            ),
          ],
          trailing: [
            _ShareButton(),
            _AccountButton(),
          ],
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
                      child: NodeGraphPanel(root: exampleNodeGraph),
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
                      child: PropertiesWidget(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

abstract class EditorPanel extends StatelessWidget {
  const EditorPanel({super.key});
}

class PropertiesWidget extends EditorPanel {
  const PropertiesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container();
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
