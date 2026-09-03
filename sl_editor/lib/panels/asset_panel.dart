import 'dart:async';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:sl_editor/client/assets/asset_blob_transferer.dart';
import 'package:sl_editor/assets.dart';
import 'package:sl_editor/client/assets/asset_thumbs.dart';
import 'package:sl_editor/client/client.dart';
import 'package:sl_shared/sl_shared.dart';

class AssetPanel extends StatelessWidget {
  const AssetPanel({super.key});

  void _onDropFiles(DropDoneDetails details) async {
    await Assets.import(null, details.files);
  }

  // void _onPickFiles() async {}

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
              ShadBreadcrumbDropdown(
                items: [
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
              // SizedBox(width: 8.0),
              // ShadIconButton.ghost(
              //   backgroundColor: Color(0x00000000),
              //   hoverBackgroundColor: Color(0x00000000),
              //   pressedBackgroundColor: Color(0x00000000),
              //   padding: EdgeInsets.zero,
              //   width: 22.0,
              //   height: 22.0,
              //   onPressed: () {
              //     _onPickFiles();
              //   },
              //   iconSize: 18.0,
              //   icon: Icon(LucideIcons.download),
              // ),
              SizedBox(width: 8.0),
            ],
          ),
        ),
        SizedBox(height: 4.0),
        Expanded(
          child: DropTarget(
            onDragDone: _onDropFiles,
            child: _AssetDirectoryViewer(directory: null),
          ),
        ),
      ],
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
                    key: ValueKey(asset.updatedAt),
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

  void _openAsset() {
    switch (widget.asset.type) {
      case .nodeTree:
        Client.get().sceneSystem.loadScene(widget.asset.uuid, widget.asset.name);
        break;
      default:
        break;
    }
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
                enabled: true,
                child: Text(widget.asset.name),
              ),
            ),
            ShadContextMenuItem(
              onPressed: _openAsset,
              child: Text('Open'),
            ),
            ShadContextMenuItem(
              child: Text('Rename'),
            ),
            ShadSeparator.horizontal(
              margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
            ),
            ShadContextMenuItem(
              buttonVariant: ShadButtonVariant.destructive,
              child: Text('Delete'),
              onPressed: () {
                Assets.tryDeleteAssets({widget.asset.uuid});
              },
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
