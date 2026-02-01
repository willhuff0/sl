import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:sl_editor/widgets/window_title_bar.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          WindowTitleBar(
            height: 60.0,
            trailing: [],
          ),
          SizedBox(height: 8.0),
          Padding(
            padding: const EdgeInsets.only(bottom: 14.0, left: 48.0, right: 48.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'SLGL Editor',
                  style: ShadTheme.of(context).textTheme.h1,
                ),
                Expanded(child: Container()),
                ShadButton.secondary(
                  leading: Icon(LucideIcons.import),
                  child: Text('Import'),
                ),
                SizedBox(width: 8.0),
                ShadButton(
                  leading: Icon(LucideIcons.folderPlus),
                  child: Text('Create Project'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 24.0, bottom: 24.0, left: 48.0, right: 48.0),
              children: [
                ShadCard(
                  rowCrossAxisAlignment: CrossAxisAlignment.center,
                  title: Text('Factory Game'),
                  description: Text(r'E:\Development\SLGL\Factory Game'),
                  trailing: Row(
                    children: [
                      ShadButton(
                        onPressed: () {},
                        child: Text('Open'),
                      ),
                      SizedBox(width: 8.0),
                      ShadIconButton.secondary(
                        onPressed: () {},
                        icon: Icon(LucideIcons.ellipsis),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
