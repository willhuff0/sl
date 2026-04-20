import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:sl_editor/client/client.dart';
import 'package:sl_editor/smooth_scroll_controller.dart';
import 'package:sl_editor/widgets/properties_field.dart';
import 'package:sl_engine/editor/selector.dart';

class PropertiesPanel extends StatelessWidget {
  const PropertiesPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ShadCard(
          border: ShadBorder(
            bottom: ShadBorderSide(
              color: ShadTheme.of(context).colorScheme.border,
              width: 2.0,
              strokeAlign: BorderSide.strokeAlignOutside,
            ),
          ),
          padding: EdgeInsets.symmetric(vertical: 7.0),
          child: Row(
            children: [
              SizedBox(width: 8.0),
              Text('Properties'),
              Expanded(child: Container()),
              // ShadBreadcrumbDropdown(
              //   items: [
              //     ShadBreadcrumbDropMenuItem(
              //       child: Text('Cube'),
              //       onPressed: () {},
              //     ),
              //   ],
              //   showDropdownArrow: true,
              //   arrowGap: 0.0,
              //   anchor: ShadAnchor(
              //     childAlignment: Alignment.topRight,
              //     overlayAlignment: Alignment.bottomRight,
              //   ),
              //   child: Icon(
              //     LucideIcons.plus,
              //     color: ShadTheme.of(context).colorScheme.foreground,
              //     size: 22.0,
              //   ),
              // ),
              SizedBox(width: 8.0),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: _PropertiesWidget(),
          ),
        ),
      ],
    );
  }
}

class _PropertiesWidget extends StatefulWidget {
  const _PropertiesWidget({super.key});

  @override
  State<_PropertiesWidget> createState() => _PropertiesWidgetState();
}

class _PropertiesWidgetState extends State<_PropertiesWidget> {
  late final SmoothScrollController _scrollController;
  late final StreamSubscription _onSelectionChangedSubscription;

  @override
  void initState() {
    _scrollController = SmoothScrollController();
    _onSelectionChangedSubscription = Selector.onSelectionChanged.listen((_) => setState(() {}));
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _onSelectionChangedSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Selector.getSelected().isEmpty) {
      return Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24.0),
          child: Text('Nothing selected.'),
        ),
      );
    }
    if (Selector.getSelected().length > 1) {
      return Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24.0),
          child: Text('Multiple selection editing is not supported.'),
        ),
      );
    }

    final selected = Selector.getSelected().first;
    final tracked = Client.get().sceneSystem.getTrackedFromEngineNode(selected);

    return ListView(
      controller: _scrollController,
      padding: EdgeInsets.all(8.0),
      shrinkWrap: true,
      children: [
        PropertiesFieldWithLabel(
          label: 'Name',
          tracked: tracked,
          property: tracked.name,
          onChanged: () {
            Client.get().sceneSystem.onNodeAddedOrRemovedController.add(null);
          },
        ),
        SizedBox(height: 14.0),

        PropertiesFieldWithLabel(
          label: 'Local Position',
          tracked: tracked,
          property: tracked.lPos,
        ),
        SizedBox(height: 8.0),

        PropertiesFieldWithLabel(
          label: 'Local Rotation',
          tracked: tracked,
          property: tracked.lRot,
        ),
        SizedBox(height: 8.0),

        PropertiesFieldWithLabel(
          label: 'Local Scale',
          tracked: tracked,
          property: tracked.lScale,
        ),
        SizedBox(height: 8.0),
      ],
    );
  }
}
