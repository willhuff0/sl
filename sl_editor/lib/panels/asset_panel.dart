import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart' show SelectableText;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:sl_editor/client/assets/asset_blob_transferer.dart';
import 'package:sl_editor/assets.dart';
import 'package:sl_editor/client/assets/asset_thumbs.dart';
import 'package:sl_editor/client/client.dart';
import 'package:sl_editor/widgets/shad_breadcrumb_dropdown.dart';
import 'package:sl_editor/widgets/upload_zone.dart';
import 'package:sl_shared/sl_shared.dart';

class AssetPanel extends StatefulWidget {
  const AssetPanel({super.key});

  @override
  State<AssetPanel> createState() => _AssetPanelState();
}

class _AssetPanelState extends State<AssetPanel> {
  final _directories = <(UUID, String)>[];

  void _onDropFiles(List<UploadFile> files) async {
    await Assets.import(_directories.lastOrNull?.$1, files);
  }

  void _onCreateFolder(BuildContext context) {
    showShadDialog(
      context: context,
      builder: (context) => _CreateAssetDialog(
        typeDisplayName: 'Folder',
        defaultName: 'New Folder',
        defaultNameIsAn: false,
        createAsset: (name) async {
          await Assets.createDirectory(_directories.lastOrNull?.$1, name);
        },
      ),
    );
  }

  void _onCreateScene(BuildContext context) {
    showShadDialog(
      context: context,
      builder: (context) => _CreateAssetDialog(
        typeDisplayName: 'Scene',
        defaultName: 'New Scene',
        defaultNameIsAn: false,
        createAsset: (name) async {
          await Assets.createScene(_directories.lastOrNull?.$1, name);
        },
      ),
    );
  }

  void _pushDirectory(UUID directory, String name) {
    setState(() => _directories.add((directory, name)));
  }

  void _jumpToDirectory(UUID? directory) {
    if (directory == _directories.lastOrNull?.$1) return;
    if (directory == null) {
      setState(() => _directories.clear());
      return;
    }

    while (_directories.isNotEmpty && _directories.last.$1 != directory) {
      _directories.removeLast();
    }
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
                child: Text('Assets'),
                onPressed: () => _jumpToDirectory(null),
              ),
              Expanded(
                child: _directories.isEmpty
                    ? Container()
                    : Row(
                        children: [
                          for (final (directory, name) in _directories) ...[
                            Icon(LucideIcons.chevronRight),
                            ShadButton.ghost(
                              padding: EdgeInsets.symmetric(horizontal: 4.0),
                              height: 22.0,
                              child: Text(name),
                              onPressed: () => _jumpToDirectory(directory),
                            ),
                          ],
                        ],
                      ),
              ),
              MyShadDropdown(
                items: [
                  ShadBreadcrumbDropMenuItem(
                    child: Text('Folder'),
                    onPressed: () => _onCreateFolder(context),
                  ),
                  ShadBreadcrumbDropMenuItem(
                    child: Text('Scene'),
                    onPressed: () => _onCreateScene(context),
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
        SizedBox(height: 4.0),
        Expanded(
          child: UploadZoneWidget(
            onDrop: _onDropFiles,
            child: _AssetDirectoryViewer(
              key: ValueKey(_directories.lastOrNull?.$1),
              directory: _directories.lastOrNull?.$1,
              pushDirectory: _pushDirectory,
            ),
          ),
        ),
      ],
    );
  }
}

class _AssetDirectoryViewer extends StatefulWidget {
  final UUID? directory;
  final void Function(UUID directory, String name) pushDirectory;

  const _AssetDirectoryViewer({
    super.key,
    required this.directory,
    required this.pushDirectory,
  });

  @override
  State<_AssetDirectoryViewer> createState() => __AssetDirectoryViewerState();
}

class __AssetDirectoryViewerState extends State<_AssetDirectoryViewer> {
  Map<UUID, Asset>? _assets;
  List<FoldedAsset>? _foldedAssets;
  late final StreamSubscription _subscription;

  @override
  void initState() {
    _subscription = Client.get().assetSystem.sharedDatabase.watchAssetsInDirectory(widget.directory).listen((event) {
      setState(() {
        _assets = event.$1;
        _foldedAssets = event.$2;
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _assets == null
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: 96.0,
                height: 4.0,
                child: ShadProgress(),
              ),
            ),
          )
        : SingleChildScrollView(
            padding: EdgeInsets.all(8.0),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: _foldedAssets!.map(
                (foldedAsset) {
                  final asset = _assets![foldedAsset.uuid]!;
                  return _AssetEntryWidget(
                    key: ValueKey(asset.uuid),
                    asset: asset,
                    assets: _assets!,
                    folded: foldedAsset,
                    pushDirectory: widget.pushDirectory,
                  );
                },
              ).toList(),
            ),
          );
  }
}

class _AssetEntryWidget extends StatefulWidget {
  final Asset asset;

  final Map<UUID, Asset> assets;
  final FoldedAsset folded;

  final void Function(UUID directory, String name) pushDirectory;

  const _AssetEntryWidget({
    super.key,
    required this.asset,
    required this.assets,
    required this.folded,
    required this.pushDirectory,
  });

  @override
  State<_AssetEntryWidget> createState() => _AssetEntryWidgetState();
}

class _AssetEntryWidgetState extends State<_AssetEntryWidget> {
  final GlobalKey _cardKey = GlobalKey();
  final GlobalKey _floatingCardKey = GlobalKey();

  late final StreamSubscription _tempProgressChangedSubscription;
  final Map<UUID, AssetTransferProgress> _progresses = {};
  var progress = 1.0;

  Set<UUID> _getAllUuids(FoldedAsset folded) {
    final uuids = {folded.uuid};
    for (final sub in folded.subAssets) {
      uuids.addAll(_getAllUuids(sub));
    }
    return uuids;
  }

  @override
  void initState() {
    _tempProgressChangedSubscription = tempProgressChanged.listen((event) {
      if (!mounted) return;

      final allUuids = _getAllUuids(widget.folded);
      if (allUuids.contains(event.$1)) {
        _progresses[event.$1] = event.$2;

        int totalSize = 0;
        int completedSize = 0;

        for (final uuid in allUuids) {
          final asset = widget.assets[uuid];
          final p = _progresses[uuid];
          final size = p?.byteLength ?? asset?.blobSize;

          if (size != null) {
            totalSize += size;
            if (p != null) {
              completedSize += p.bytesCompleted;
            }
          }
        }

        setState(() {
          if (totalSize > 0) {
            progress = completedSize / totalSize;
          } else {
            progress = event.$2.progress;
          }
        });
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _tempProgressChangedSubscription.cancel();
    super.dispose();
  }

  static const _openableAssetTypes = <AssetType>{
    .directory,
    .nodeTree,
  };
  void _openAsset() {
    switch (widget.asset.type) {
      case .directory:
        widget.pushDirectory(widget.asset.uuid, widget.asset.name);
        break;
      case .nodeTree:
        Client.get().sceneSystem.loadScene(widget.asset.uuid, widget.asset.name);
        break;
      default:
        break;
    }
  }

  void _showAssetDetails() {
    showShadDialog(
      context: context,
      builder: (context) => _AssetDetailsDialog(
        asset: widget.asset,
      ),
    );
  }

  void _showAssetRename() {
    showShadDialog(
      context: context,
      builder: (context) => _AssetRenameDialog(
        asset: widget.asset,
      ),
    );
  }

  void _showAssetDelete() {
    showShadDialog(
      context: context,
      builder: (context) => _AssetDeleteDialog(
        asset: widget.asset,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget getEntryVisual(Key cardKey) => SizedBox(
      width: 200.0 / 1.5,
      height: 214.0 / 1.5,
      child: ShadCard(
        padding: EdgeInsets.zero,
        child: progress < 0.999
            ? Stack(
                children: [
                  Positioned.fill(
                    child: _AssetCardWidget(key: cardKey, asset: widget.asset),
                  ),
                  Positioned.fill(
                    bottom: 214.0 / 1.5 - 6,
                    child: ShadProgress(
                      value: progress,
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                ],
              )
            : _AssetCardWidget(key: cardKey, asset: widget.asset),
      ),
    );

    return Draggable<Asset>(
      data: widget.asset,
      feedback: getEntryVisual(_floatingCardKey),
      childWhenDragging: Opacity(
        opacity: 0.6,
        child: getEntryVisual(_cardKey),
      ),
      child: GestureDetector(
        onDoubleTap: _openAsset,
        child: ShadContextMenuRegion(
          items: [
            ShadTooltip(
              waitDuration: Duration(milliseconds: 1000),
              builder: (context) {
                return Text(widget.asset.uuid);
              },
              child: ShadContextMenuItem(
                onPressed: _showAssetDetails,
                child: Text(widget.asset.name),
              ),
            ),
            if (_openableAssetTypes.contains(widget.asset.type))
              ShadContextMenuItem(
                onPressed: _openAsset,
                child: Text('Open'),
              ),
            ShadContextMenuItem(
              onPressed: _showAssetRename,
              child: Text('Rename'),
            ),
            ShadSeparator.horizontal(
              margin: EdgeInsets.only(bottom: 4.0, top: 6.0, left: 4.0, right: 4.0),
            ),
            Padding(
              padding: const EdgeInsets.all(2.0),
              child: ShadContextMenuItem(
                buttonVariant: ShadButtonVariant.destructive,
                onPressed: _showAssetDelete,
                child: Text('Delete'),
              ),
            ),
          ],
          child: getEntryVisual(_cardKey),
        ),
      ),
    );
  }
}

class _AssetCardWidget extends StatefulWidget {
  final Asset asset;

  const _AssetCardWidget({super.key, required this.asset});

  @override
  State<_AssetCardWidget> createState() => __AssetCardWidgetState();
}

class __AssetCardWidgetState extends State<_AssetCardWidget> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, right: 4.0, top: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _AssetThumbWidget(
              key: ValueKey(widget.asset.uuid),
              asset: widget.asset,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4.0, right: 4.0, top: 2.0, bottom: 2.0),
            child: Text(
              widget.asset.name,
              style: TextStyle(fontSize: 11.0),
              maxLines: 2,
              overflow: TextOverflow.fade,
            ),
          ),
        ],
      ),
    );
  }
}

class _AssetThumbWidget extends StatefulWidget {
  final Asset asset;

  const _AssetThumbWidget({super.key, required this.asset});

  @override
  State<_AssetThumbWidget> createState() => _AssetThumbWidgetState();
}

class _AssetThumbWidgetState extends State<_AssetThumbWidget> {
  late final String uri;
  String? _mime;

  @override
  void initState() {
    uri = AssetThumbs.getUri(widget.asset.uuid);

    if (widget.asset.type != .unsupported && widget.asset.type != .directory) {
      _mime = AssetThumbs.getCachedMime(widget.asset.uuid);
      if (_mime == null) _load();
    }

    super.initState();
  }

  Future<void> _load() async {
    final mime = await AssetThumbs.getMime(widget.asset.uuid);
    if (!mounted) return;
    setState(() {
      _mime = mime;
    });
  }

  Widget _getPlaceholder(BuildContext context, AssetType type) {
    const size = 48.0;
    final color = ShadTheme.of(context).colorScheme.mutedForeground;
    return switch (type) {
      .directory => Icon(LucideIcons.folder, size: size, color: color),
      .unsupported => Icon(LucideIcons.fileQuestionMark, size: size, color: color),
      .propertiesOnly => Icon(LucideIcons.braces, size: size, color: color),
      .texture => Icon(LucideIcons.image, size: size, color: color),
      .hdri => Icon(LucideIcons.cloudSun, size: size, color: color),
      .mesh => Icon(LucideIcons.pyramid, size: size, color: color),
      .model => Icon(LucideIcons.box, size: size, color: color),
      .shader => Icon(LucideIcons.code, size: size, color: color),
      .nodeTree => Icon(LucideIcons.globe, size: size, color: color),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(0.0),
      child: _mime == null
          ? Center(child: _getPlaceholder(context, widget.asset.type))
          : Container(
              decoration: BoxDecoration(
                color: ShadTheme.of(context).colorScheme.accent,
                borderRadius: BorderRadius.circular(4.0),
                image: DecorationImage(
                  image: NetworkImage(uri),
                  fit: BoxFit.contain,
                ),
              ),
            ),
    );
  }
}

String _formatBlobSize(int bytes, {int decimals = 2}) {
  if (bytes <= 0) return "0 B";

  const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB"];

  // Calculate the exponent base 1000
  var i = (log(bytes) / log(1000)).floor();

  // Ensure we don't exceed the bounds of the suffix array
  i = min(i, suffixes.length - 1);

  // Calculate the final readable size
  var size = bytes / pow(1000, i);

  return "${size.toStringAsFixed(decimals)} ${suffixes[i]}";
}

class _AssetDetailsDialog extends StatelessWidget {
  final Asset asset;

  const _AssetDetailsDialog({
    super.key,
    required this.asset,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final textStyle = TextStyle(color: theme.colorScheme.foreground);

    return ShadDialog(
      title: SelectableText(asset.name),
      description: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('UUID'),
                  Text('Type'),
                  if (asset.blobSize != null) Text('Size'),
                  if (asset.blobVersion != null) Text('Version'),
                  Text('Updated'),
                ],
              ),
              SizedBox(width: 8.0),
              SelectableRegion(
                selectionControls: emptyTextSelectionControls,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(asset.uuid, style: textStyle),
                    Text(asset.type.name, style: textStyle),
                    if (asset.blobSize != null) Text(_formatBlobSize(asset.blobSize!), style: textStyle),
                    if (asset.blobVersion != null) Text(asset.blobVersion.toString(), style: textStyle),
                    Text(DateFormat('h:mm a, MMM d, y').format(asset.updatedAt), style: textStyle),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AssetDeleteDialog extends StatelessWidget {
  final Asset asset;

  const _AssetDeleteDialog({
    super.key,
    required this.asset,
  });

  void _confirm(BuildContext context) {
    Assets.tryDeleteAssets({asset.uuid});
    Navigator.pop(context);
  }

  void _cancel(BuildContext context) {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return ShadDialog.alert(
      title: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'Delete ',
              style: TextStyle(fontWeight: .normal),
            ),
            TextSpan(
              text: asset.name,
              style: TextStyle(fontWeight: .bold),
            ),
            TextSpan(
              text: '?',
              style: TextStyle(fontWeight: .normal),
            ),
          ],
        ),
      ),
      gap: 24.0,
      actions: [
        ShadButton.outline(
          onPressed: () => _cancel(context),
          child: Text('Back'),
        ),
        ShadButton.destructive(
          onPressed: () => _confirm(context),
          child: Text('Delete'),
        ),
      ],
    );
  }
}

class _AssetRenameDialog extends StatefulWidget {
  final Asset asset;

  const _AssetRenameDialog({
    super.key,
    required this.asset,
  });

  @override
  State<_AssetRenameDialog> createState() => _AssetRenameDialogState();
}

class _AssetRenameDialogState extends State<_AssetRenameDialog> {
  final _formKey = GlobalKey();
  late final TextEditingController _textEditingController;

  @override
  void initState() {
    _textEditingController = TextEditingController(text: widget.asset.name);
    super.initState();
  }

  void _confirm(BuildContext context) {
    if (_formKey.currentContext == null) return;
    final formState = _formKey.currentState as FormState;

    if (!formState.validate()) return;
    formState.save();

    Navigator.pop(context);
  }

  void _cancel(BuildContext context) {
    Navigator.pop(context);
  }

  String? _validate(String value) {
    value = value.trim();
    if (value.isEmpty) return 'You can\'t name an asset nothing';
    if (value.length > 128) return 'Must be < 128 characters';
    return null;
  }

  void _onSave(String? value) async {
    value = value!.trim();

    final db = Client.get().assetSystem.sharedDatabase;
    await db.execute(
      'UPDATE assets SET name = ? WHERE uuid = ?',
      [value, widget.asset.uuid],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ShadDialog.alert(
      title: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'Rename ',
              style: TextStyle(fontWeight: .normal),
            ),
            TextSpan(
              text: widget.asset.name,
              style: TextStyle(fontWeight: .bold),
            ),
            TextSpan(
              text: '.',
              style: TextStyle(fontWeight: .normal),
            ),
          ],
        ),
      ),
      description: Shortcuts(
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.keyW): DoNothingAndStopPropagationIntent(),
          SingleActivator(LogicalKeyboardKey.keyE): DoNothingAndStopPropagationIntent(),
          SingleActivator(LogicalKeyboardKey.keyR): DoNothingAndStopPropagationIntent(),
        },
        child: Form(
          key: _formKey,
          child: ShadInputFormField(
            controller: _textEditingController,
            autofocus: true,
            maxLength: 128,
            validator: _validate,
            onSaved: _onSave,
            onEditingComplete: () => _confirm(context),
          ),
        ),
      ),
      gap: 24.0,
      actions: [
        ShadButton.outline(
          onPressed: () => _cancel(context),
          child: Text('Back'),
        ),
        ShadButton(
          onPressed: () => _confirm(context),
          child: Text('Rename'),
        ),
      ],
    );
  }
}

class _CreateAssetDialog extends StatefulWidget {
  final String typeDisplayName;
  final String defaultName;
  final bool defaultNameIsAn;
  final void Function(String name) createAsset;

  const _CreateAssetDialog({
    super.key,
    required this.typeDisplayName,
    required this.defaultName,
    this.defaultNameIsAn = false,
    required this.createAsset,
  });

  @override
  State<_CreateAssetDialog> createState() => _CreateAssetDialogState();
}

class _CreateAssetDialogState extends State<_CreateAssetDialog> {
  final _formKey = GlobalKey();
  late final TextEditingController _textEditingController;

  @override
  void initState() {
    _textEditingController = TextEditingController(text: widget.defaultName);
    super.initState();
  }

  void _confirm(BuildContext context) {
    if (_formKey.currentContext == null) return;
    final formState = _formKey.currentState as FormState;

    if (!formState.validate()) return;
    formState.save();

    Navigator.pop(context);
  }

  void _cancel(BuildContext context) {
    Navigator.pop(context);
  }

  String? _validate(String value) {
    value = value.trim();
    if (value.isEmpty) {
      return 'You can\'t name ${widget.defaultNameIsAn ? 'an' : 'a'} ${widget.typeDisplayName} nothing';
    }
    if (value.length > 128) return 'Must be < 128 characters';
    return null;
  }

  void _onSave(String? value) {
    value = value!.trim();
    widget.createAsset(value);
  }

  @override
  Widget build(BuildContext context) {
    return ShadDialog.alert(
      title: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'Create a new ',
              style: TextStyle(fontWeight: .normal),
            ),
            TextSpan(
              text: widget.typeDisplayName,
              style: TextStyle(fontWeight: .bold),
            ),
            TextSpan(
              text: '.',
              style: TextStyle(fontWeight: .normal),
            ),
          ],
        ),
      ),
      description: Shortcuts(
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.keyW): DoNothingAndStopPropagationIntent(),
          SingleActivator(LogicalKeyboardKey.keyE): DoNothingAndStopPropagationIntent(),
          SingleActivator(LogicalKeyboardKey.keyR): DoNothingAndStopPropagationIntent(),
        },
        child: Form(
          key: _formKey,
          child: ShadInputFormField(
            controller: _textEditingController,
            autofocus: true,
            maxLength: 128,
            validator: _validate,
            onSaved: _onSave,
            onEditingComplete: () => _confirm(context),
          ),
        ),
      ),
      gap: 24.0,
      actions: [
        ShadButton.outline(
          onPressed: () => _cancel(context),
          child: Text('Back'),
        ),
        ShadButton(
          onPressed: () => _confirm(context),
          child: Text('Create'),
        ),
      ],
    );
  }
}
