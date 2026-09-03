import 'dart:async';
import 'dart:math';

import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart' show SelectableText;
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:sl_editor/client/assets/asset_blob_transferer.dart';
import 'package:sl_editor/assets.dart';
import 'package:sl_editor/client/assets/asset_thumbs.dart';
import 'package:sl_editor/client/client.dart';
import 'package:sl_editor/widgets/shad_breadcrumb_dropdown.dart';
import 'package:sl_shared/sl_shared.dart';

class AssetPanel extends StatelessWidget {
  const AssetPanel({super.key});

  void _onDropFiles(List<XFile> files) async {
    await Assets.import(null, files);
  }

  void _onPickFiles() async {
    final platformFiles = await FilePicker.pickFiles();
    final xFiles = platformFiles.map((platformFile) => platformFile.xFile).toList();
    await Assets.import(null, xFiles);
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
              Text('Assets'),
              Expanded(child: Container()),
              MyShadDropdown(
                items: [
                  ShadBreadcrumbDropMenuItem(
                    onPressed: _onPickFiles,
                    child: Row(
                      children: [
                        Icon(LucideIcons.upload),
                        SizedBox(width: 8.0),
                        Text('Upload'),
                      ],
                    ),
                  ),
                  ShadSeparator.horizontal(
                    margin: EdgeInsets.symmetric(vertical: 4.0),
                  ),
                  ShadBreadcrumbDropMenuItem(
                    child: Text('Scene'),
                    onPressed: () async {
                      await Assets.createScene(null);
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
          child: _AssetPanelDropZone(
            onDrop: _onDropFiles,
            child: _AssetDirectoryViewer(directory: null),
          ),
        ),
      ],
    );
  }
}

class _AssetPanelDropZone extends StatefulWidget {
  final void Function(List<XFile> files) onDrop;
  final Widget child;

  const _AssetPanelDropZone({
    super.key,
    required this.onDrop,
    required this.child,
  });

  @override
  State<_AssetPanelDropZone> createState() => __AssetPanelDropZoneState();
}

class __AssetPanelDropZoneState extends State<_AssetPanelDropZone> {
  var _isHovered = false;

  void _onDropHoverEnter(DropEventDetails details) {
    setState(() => _isHovered = true);
  }

  void _onDropHoverExit(DropEventDetails details) {
    setState(() => _isHovered = false);
  }

  void _onDropFiles(DropDoneDetails details) {
    widget.onDrop(details.files);
  }

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragEntered: _onDropHoverEnter,
      onDragExited: _onDropHoverExit,
      onDragDone: _onDropFiles,
      child: Stack(
        fit: .expand,
        children: [
          widget.child,
          AnimatedOpacity(
            duration: Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            opacity: _isHovered ? 1.0 : 0.0,
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: ShadTheme.of(context).colorScheme.background,
                      blurRadius: 24.0,
                      spreadRadius: 14.0,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.upload, size: 24.0),
                    SizedBox(height: 14.0),
                    Text('Drop to upload assets'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssetDirectoryViewer extends StatefulWidget {
  final UUID? directory;

  const _AssetDirectoryViewer({super.key, required this.directory});

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
            child: ShadProgress(),
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

  const _AssetEntryWidget({
    super.key,
    required this.asset,
    required this.assets,
    required this.folded,
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
    .nodeTree,
  };
  void _openAsset() {
    switch (widget.asset.type) {
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

  // Calculate the exponent base 1024
  var i = (log(bytes) / log(1024)).floor();

  // Ensure we don't exceed the bounds of the suffix array
  i = min(i, suffixes.length - 1);

  // Calculate the final readable size
  var size = bytes / pow(1024, i);

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
