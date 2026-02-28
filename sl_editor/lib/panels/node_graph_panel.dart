import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:sl_engine/editor_utils/selector.dart';
import 'package:sl_engine/node.dart';

class NodeGraphPanel extends StatefulWidget {
  final Node root;
  final Set<Node>? expanded;

  const NodeGraphPanel({
    super.key,
    required this.root,
    this.expanded,
  });

  @override
  State<NodeGraphPanel> createState() => _NodeGraphPanelState();
}

class _NodeGraphPanelState extends State<NodeGraphPanel> {
  late final Set<Node> expanded;

  @override
  void initState() {
    expanded = widget.expanded ?? {};
    super.initState();
  }

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
              Text('Node Hierarchy'),
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
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: _NodeTreeWidget(
              root: widget.root,
              expanded: expanded,
            ),
          ),
        ),
      ],
    );
  }
}

class _NodeTreeWidget extends StatefulWidget {
  final Node root;
  final Set<Node> expanded;

  const _NodeTreeWidget({
    super.key,
    required this.root,
    required this.expanded,
  });

  @override
  State<_NodeTreeWidget> createState() => _NodeTreeWidgetState();
}

class _NodeTreeWidgetState extends State<_NodeTreeWidget> {
  late final StreamSubscription _onSelectionChangedSubscription;

  @override
  void initState() {
    _onSelectionChangedSubscription = Selector.onSelectionChanged.listen((_) => setState(() {}));
    super.initState();
  }

  @override
  void dispose() {
    _onSelectionChangedSubscription.cancel();
    super.dispose();
  }

  List<Widget> _recurseNode(Node node, int depth) {
    final bool isExpanded = widget.expanded.contains(node);
    final bool isSelected = Selector.getSelected().contains(node);
    return [
      _NodeWidget(
        node: node,
        depth: depth,
        isExpandable: node.children.isNotEmpty,
        isExpanded: isExpanded,
        onExpand: () {
          if (!mounted) return;
          if (isExpanded) {
            setState(() => widget.expanded.remove(node));
          } else {
            setState(() => widget.expanded.add(node));
          }
        },
        isSelected: isSelected,
        areAnyChildrenSelectedAndIsCollapsed: !isExpanded && node.children.any(Selector.getSelected().contains),
        onSelect: () {
          if (!mounted) return;
          if (HardwareKeyboard.instance.isControlPressed) {
            Selector.toggleNode(node);
          } else {
            if (Selector.getSelected().isEmpty ||
                Selector.getSelected().length > 1 ||
                (!isSelected && Selector.getSelected().length == 1)) {
              Selector.selectOnly(node);
            } else {
              Selector.clear();
            }
          }
        },
      ),
      if (isExpanded) ...node.children.expand((c) => _recurseNode(c, depth + 1)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Selector.clear();
      },
      child: Container(
        color: Color(0x00000000),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _recurseNode(widget.root, 0),
        ),
      ),
    );
  }
}

class _NodeWidget extends StatelessWidget {
  final Node node;
  final int depth;

  final bool isExpandable;
  final bool isExpanded;
  final VoidCallback onExpand;

  final bool isSelected;
  final bool areAnyChildrenSelectedAndIsCollapsed;
  final VoidCallback onSelect;

  const _NodeWidget({
    super.key,
    required this.node,
    required this.depth,
    required this.isExpandable,
    required this.isExpanded,
    required this.onExpand,
    required this.isSelected,
    required this.areAnyChildrenSelectedAndIsCollapsed,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30.0,
      child: Row(
        children: [
          if (isExpandable)
            ShadIconButton.ghost(
              onPressed: onExpand,
              width: 32.0,
              icon: Icon(isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown),
            )
          else
            SizedBox(width: 32.0),
          // ShadIconButton.ghost(
          //   enabled: false,
          //   width: 32.0,
          //   icon: Icon(LucideIcons.circleSmall, size: 14.0),
          // ),
          ...Iterable.generate(depth, (_) => _IndentGuide()),
          ShadButton.ghost(
            backgroundColor: isSelected ? ShadTheme.of(context).colorScheme.selection.withValues(alpha: 0.6) : null,
            hoverBackgroundColor: isSelected
                ? ShadTheme.of(context).colorScheme.selection
                : ShadTheme.of(context).colorScheme.selection.withValues(alpha: 0.4),
            padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
            onPressed: onSelect,
            child: Text(node.name),
          ),
          if (areAnyChildrenSelectedAndIsCollapsed) ...[
            SizedBox(width: 8.0),
            Icon(LucideIcons.dot),
          ],
        ],
      ),
    );
  }
}

class _IndentGuide extends StatelessWidget {
  const _IndentGuide({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 14.0,
      height: 36.0,
      child: ShadSeparator.vertical(
        margin: EdgeInsets.only(left: 6.0),
      ),
    );
  }
}
