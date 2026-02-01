import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class AssetPanel extends StatelessWidget {
  const AssetPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShadCard(
            padding: EdgeInsets.symmetric(vertical: 7.0),
            child: Row(
              children: [
                SizedBox(width: 8.0),
                Text('Assets'),
                Expanded(child: Container()),
                ShadBreadcrumbDropdown(
                  items: [
                    ShadBreadcrumbDropMenuItem(
                      child: Text('Cube'),
                      onPressed: () {},
                    ),
                  ],
                  showDropdownArrow: true,
                  arrowGap: 0.0,
                  anchor: ShadAnchor(
                    childAlignment: Alignment.topRight,
                    overlayAlignment: Alignment.bottomRight,
                  ),
                  child: Icon(
                    LucideIcons.plus,
                    color: ShadTheme.of(context).colorScheme.foreground,
                    size: 22.0,
                  ),
                ),
                SizedBox(width: 8.0),
                ShadIconButton.ghost(
                  backgroundColor: Color(0x00000000),
                  hoverBackgroundColor: Color(0x00000000),
                  pressedBackgroundColor: Color(0x00000000),
                  padding: EdgeInsets.zero,
                  width: 22.0,
                  height: 22.0,
                  onPressed: () {},
                  iconSize: 18.0,
                  icon: Icon(LucideIcons.upload),
                ),
                SizedBox(width: 8.0),
              ],
            ),
          ),
          SizedBox(height: 4.0),
        ],
      ),
    );
  }
}
