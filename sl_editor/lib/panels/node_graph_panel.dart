import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:sl_editor/client/client.dart';
import 'package:sl_editor/widgets/delete_dialog.dart';
import 'package:sl_editor/widgets/rename_dialog.dart';
import 'package:sl_editor/widgets/shad_breadcrumb_dropdown.dart';
import 'package:sl_engine/editor/selector.dart';
import 'package:sl_editor/client/scenes/node.dart' as editor;
import 'package:sl_shared/sl_shared.dart';
import 'package:vector_math/vector_math.dart';

Color? _vec4ToColor(Vector4? vec) {
  if (vec == null) return null;
  return Color.from(alpha: vec.a, red: vec.r, green: vec.g, blue: vec.b);
}

class NodeGraphPanel extends StatefulWidget {
  final Set<editor.Node>? collapsed;

  const NodeGraphPanel({
    super.key,
    this.collapsed,
  });

  @override
  State<NodeGraphPanel> createState() => _NodeGraphPanelState();
}

class _NodeGraphPanelState extends State<NodeGraphPanel> {
  late final Set<editor.Node> collapsed;

  late final StreamSubscription _onRootChangedSubscription;
  late final StreamSubscription _onNodeAddedOrRemovedSubscription;

  editor.Node? _root;

  @override
  void initState() {
    collapsed = widget.collapsed ?? {};
    _onRootChangedSubscription = Client.get().sceneSystem.onRootChanged.listen(_onRootChanged);
    _onNodeAddedOrRemovedSubscription = Client.get().sceneSystem.onNodeAddedOrRemoved.listen(_onNodeAddedOrRemoved);
    super.initState();
  }

  @override
  void dispose() {
    _onRootChangedSubscription.cancel();
    _onNodeAddedOrRemovedSubscription.cancel();
    super.dispose();
  }

  void _onRootChanged(editor.Node? newRoot) {
    if (!mounted) return;
    setState(() {
      _root = newRoot;
    });
  }

  void _onNodeAddedOrRemoved(_) {
    if (!mounted) return;
    setState(() {});
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
              ShadButton.ghost(
                padding: EdgeInsets.symmetric(horizontal: 4.0),
                height: 22.0,
                child: Text('Node Tree'),
                onPressed: () {
                  Client.get().sceneSystem.closeScene();
                },
              ),
              Expanded(
                child: _root == null
                    ? Container()
                    : Row(
                        children: [
                          Icon(LucideIcons.chevronRight),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4.0),
                            child: Text(_root!.name.value),
                          ),
                        ],
                      ),
              ),
              MyShadDropdown(
                enabled: _root != null,
                items: [
                  ShadBreadcrumbDropMenuItem(
                    child: Text('Add Empty Node'),
                    onPressed: () {
                      if (_root == null || Client.get().sceneSystem.stateTracker == null) return;
                      editor.Node.create(Client.get().sceneSystem.stateTracker!, _root!.uuid, 'New Node');
                    },
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
                  color: _root != null
                      ? ShadTheme.of(context).colorScheme.foreground
                      : ShadTheme.of(context).colorScheme.foreground.withValues(alpha: 0.6),
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
            child: _root == null
                ? Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0, horizontal: 14.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Open a ',
                                ),
                                WidgetSpan(
                                  alignment: .baseline,
                                  baseline: TextBaseline.alphabetic,
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 2.0),
                                    child: Icon(
                                      LucideIcons.globe500,
                                      size: 14.0,
                                    ),
                                  ),
                                ),
                                TextSpan(
                                  text: 'Scene',
                                  style: TextStyle(fontWeight: .bold),
                                ),
                                TextSpan(
                                  text: ' in the ',
                                ),
                                TextSpan(
                                  text: 'Assets',
                                  style: TextStyle(fontWeight: .bold),
                                ),
                                TextSpan(
                                  text: ' panel.',
                                ),
                              ],
                            ),
                            textAlign: .center,
                          ),
                          SizedBox(height: 14.0),

                          Icon(
                            LucideIcons.arrowBigDown300,
                            size: 24.0,
                          ),
                        ],
                      ),
                    ),
                  )
                : _NodeTreeWidget(
                    root: _root!,
                    collapsed: collapsed,
                  ),
          ),
        ),
      ],
    );
  }
}

class _NodeTreeWidget extends StatefulWidget {
  final editor.Node root;
  final Set<editor.Node> collapsed;

  const _NodeTreeWidget({
    super.key,
    required this.root,
    required this.collapsed,
  });

  @override
  State<_NodeTreeWidget> createState() => _NodeTreeWidgetState();
}

class _NodeTreeWidgetState extends State<_NodeTreeWidget> {
  late final StreamSubscription _onSelectionChangedSubscription;
  late final StreamSubscription _onRemoteSelectionChangedSubscription;

  late final ShadContextMenuController _contextMenuController;
  Offset? _offset;
  editor.Node? _contextMenuPrimaryNode;

  @override
  void initState() {
    _onSelectionChangedSubscription = Selector.onSelectionChanged.listen((_) {
      if (!mounted) return;
      setState(() {});
    });
    _onRemoteSelectionChangedSubscription = Selector.onRemoteSelectionChanged.listen((_) {
      if (!mounted) return;
      setState(() {});
    });
    _contextMenuController = ShadContextMenuController();
    super.initState();
  }

  @override
  void dispose() {
    _onSelectionChangedSubscription.cancel();
    _onRemoteSelectionChangedSubscription.cancel();
    _contextMenuController.dispose();
    super.dispose();
  }

  void _openContextMenu(editor.Node primary, Offset globalPosition) {
    setState(() {
      _offset = globalPosition;
      _contextMenuPrimaryNode = primary;
    });
    _contextMenuController.show();
  }

  void _hideContextMenu() {
    _contextMenuController.hide();
  }

  void _showNodeDetails(editor.Node node) {}

  final _random = Random();
  String _getRandomNeedNameQuip() {
    const quips = [
      'Your node needs a name',
      'Nodes cannot live without names',
      'Nodes can\'t stand being nameless',
      'Your node won\'t survive without a name',
      '"Please name me!" -The Node',
      'This node isn\'t leaving without a name',
    ];
    return quips[_random.nextInt(quips.length)];
  }

  void _showNodeRename(editor.Node node) {
    showShadDialog(
      context: context,
      builder: (context) => RenameDialog(
        name: node.name.value,
        validate: (value) {
          value = value.trim();
          if (value.isEmpty) return _getRandomNeedNameQuip();
          if (value.length > 128) return 'Must be < 128 characters';
          return null;
        },
        onSave: (value) async {
          node.modifyLocal((builder) {
            node.name.stage(builder, value);
          });
          Client.get().sceneSystem.onNodeAddedOrRemovedController.add(null);
        },
      ),
    );
  }

  void _showNodeDelete(List<editor.Node> nodes) {
    final name = nodes.length == 1 ? nodes.first.name.value : '${nodes.length} nodes';
    showShadDialog(
      context: context,
      builder: (context) => DeleteDialog(
        name: name,
        onDelete: () {
          for (final node in nodes) {
            if (!node.doesExist.value) continue;
            node.delete();
          }
        },
      ),
    );
  }

  List<Widget> _getSingleNodeContextMenuItems(editor.Node node) {
    return [
      ShadTooltip(
        waitDuration: Duration(milliseconds: 1000),
        builder: (context) {
          return Text(node.uuid);
        },
        child: ShadContextMenuItem(
          onPressed: () => _showNodeDetails(node),
          child: Text(node.name.value),
        ),
      ),
      ShadContextMenuItem(
        onPressed: () => _showNodeRename(node),
        child: Text('Rename'),
      ),
      ShadSeparator.horizontal(
        margin: EdgeInsets.only(bottom: 4.0, top: 6.0, left: 4.0, right: 4.0),
      ),
      Padding(
        padding: const EdgeInsets.all(2.0),
        child: ShadContextMenuItem(
          buttonVariant: ShadButtonVariant.destructive,
          onPressed: () => _showNodeDelete([node]),
          child: Text('Delete'),
        ),
      ),
    ];
  }

  List<Widget> _multiNodeContextMenuItems() {
    final nodeCount = Selector.getSelected().length;
    final nodes = Selector.getSelected().map(
      (engineNode) => Client.get().sceneSystem.getTrackedFromEngineNode(engineNode),
    );
    return [
      ShadContextMenuItem(
        child: Text('$nodeCount nodes'),
      ),
      ShadSeparator.horizontal(
        margin: EdgeInsets.only(bottom: 4.0, top: 6.0, left: 4.0, right: 4.0),
      ),
      Padding(
        padding: const EdgeInsets.all(2.0),
        child: ShadContextMenuItem(
          buttonVariant: ShadButtonVariant.destructive,
          onPressed: () => _showNodeDelete(nodes.toList()),
          child: Text('Delete'),
        ),
      ),
    ];
  }

  List<Widget> _getContextMenuItems() {
    if (_contextMenuPrimaryNode == null) return [];

    if (Selector.getSelected().length > 1 && Selector.getSelected().contains(_contextMenuPrimaryNode!.engineNode)) {
      return _multiNodeContextMenuItems();
    }

    return _getSingleNodeContextMenuItems(_contextMenuPrimaryNode!);
  }

  List<Widget> _recurseNode(editor.Node node, int depth) {
    final bool isCollapsed = widget.collapsed.contains(node);
    final bool isSelected = Selector.getSelected().contains(node.engineNode);
    return [
      _NodeWidget(
        node: node,
        depth: depth,
        isExpandable: node.children.isNotEmpty,
        isCollapsed: isCollapsed,
        onExpand: () {
          if (!mounted) return;
          if (isCollapsed) {
            setState(() => widget.collapsed.remove(node));
          } else {
            setState(() => widget.collapsed.add(node));
          }
        },
        isSelected: isSelected,
        areAnyChildrenSelectedAndIsCollapsed:
            isCollapsed && node.children.values.map((node) => node.engineNode).any(Selector.getSelected().contains),
        onSelect: () {
          if (!mounted) return;
          if (HardwareKeyboard.instance.isControlPressed) {
            Selector.toggleNode(node.engineNode);
          } else {
            if (Selector.getSelected().isEmpty ||
                Selector.getSelected().length > 1 ||
                (!isSelected && Selector.getSelected().length == 1)) {
              Selector.selectOnly(node.engineNode);
            } else {
              Selector.clear();
            }
          }
        },
        openContextMenu: (globalPosition) => _openContextMenu(node, globalPosition),
      ),
      if (!isCollapsed) ...node.children.values.expand((c) => _recurseNode(c, depth + 1)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ShadContextMenu(
      controller: _contextMenuController,
      anchor: _offset == null ? null : ShadGlobalAnchor(_offset!),
      items: _getContextMenuItems(),
      child: GestureDetector(
        onTap: () {
          Selector.clear();
          _hideContextMenu();
        },
        onSecondaryTap: () {
          _hideContextMenu();
        },
        child: Container(
          color: Color(0x00000000),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: widget.root.children.values.expand((c) => _recurseNode(c, 0)).toList(),
          ),
        ),
      ),
    );
  }
}

class _NodeWidget extends StatelessWidget {
  final editor.Node node;
  final int depth;

  final bool isExpandable;
  final bool isCollapsed;
  final VoidCallback onExpand;

  final bool isSelected;
  final bool areAnyChildrenSelectedAndIsCollapsed;
  final VoidCallback onSelect;
  final void Function(Offset globalPosition) openContextMenu;

  const _NodeWidget({
    super.key,
    required this.node,
    required this.depth,
    required this.isExpandable,
    required this.isCollapsed,
    required this.onExpand,
    required this.isSelected,
    required this.areAnyChildrenSelectedAndIsCollapsed,
    required this.onSelect,
    required this.openContextMenu,
  });

  void _onDropAsset(Asset asset) async {
    switch (asset.type) {
      case .model:
        await Client.get().sceneSystem.createNewGltfAssetNode(asset, node);
        break;
      default:
        break;
    }
  }

  void _onDropNode(editor.Node other) async {
    other.moveTo(node);
  }

  @override
  Widget build(BuildContext context) {
    final remoteSelectionColor = _vec4ToColor(Selector.getRemoteSelectionColor(node.engineNode));
    final isSelectableAndDraggable = node.parent.value != null && remoteSelectionColor == null;

    final dragTarget = DragTarget(
      onAcceptWithDetails: (details) {
        switch (details.data) {
          case editor.Node node:
            _onDropNode(node);
            break;
          case Asset asset:
            _onDropAsset(asset);
            break;
        }
      },
      builder: (context, _, _) => ShadButton.ghost(
        decoration: remoteSelectionColor != null
            ? ShadDecoration(border: ShadBorder.all(width: 2.0, color: remoteSelectionColor))
            : null,
        backgroundColor: isSelected ? ShadTheme.of(context).colorScheme.selection.withValues(alpha: 0.6) : null,
        hoverBackgroundColor: isSelected
            ? ShadTheme.of(context).colorScheme.selection
            : ShadTheme.of(context).colorScheme.selection.withValues(alpha: 0.4),
        padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
        onPressed: isSelectableAndDraggable ? onSelect : null,
        onSecondaryTapUp: (details) => openContextMenu(details.globalPosition),
        child: Text(node.name.value),
      ),
    );

    return SizedBox(
      height: 30.0,
      child: Row(
        children: [
          if (isExpandable)
            ShadIconButton.ghost(
              onPressed: onExpand,
              width: 32.0,
              icon: Icon(isCollapsed ? LucideIcons.chevronDown : LucideIcons.chevronUp),
            )
          else
            SizedBox(width: 32.0),
          ...Iterable.generate(depth, (_) => _IndentGuide()),
          if (isSelectableAndDraggable)
            Draggable<editor.Node>(
              data: node,
              feedback: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 7.0),
                decoration: BoxDecoration(
                  color: ShadTheme.of(context).colorScheme.selection.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Text(node.name.value),
              ),
              childWhenDragging: ShadButton.ghost(
                enabled: false,
                padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                child: Text(node.name.value),
              ),
              child: dragTarget,
            )
          else
            dragTarget,
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
