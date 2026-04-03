import 'dart:async';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:sl_editor/client/assets_api.dart';
import 'package:sl_shared/sl_shared.dart';

final _tC = StreamController.broadcast();
final _s = _tC.stream;

class AssetPanel extends StatelessWidget {
  const AssetPanel({super.key});

  void _onDropFiles(DropDoneDetails details) async {
    for (final file in details.files) {
      final name = file.name;
      //final bytes = await file.readAsBytes();
      await AssetsApi.createAsset(null, name, AssetType.unsupported);
      _tC.add(null);
    }
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
              ShadBreadcrumbDropdown(
                items: [
                  ShadBreadcrumbDropMenuItem(
                    child: Text('Test Asset'),
                    onPressed: () async {
                      await AssetsApi.createAsset(null, 'Test Asset', AssetType.mesh);
                      _tC.add(null);
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
              ShadIconButton.ghost(
                backgroundColor: Color(0x00000000),
                hoverBackgroundColor: Color(0x00000000),
                pressedBackgroundColor: Color(0x00000000),
                padding: EdgeInsets.zero,
                width: 22.0,
                height: 22.0,
                onPressed: () {},
                iconSize: 18.0,
                icon: Icon(LucideIcons.download),
              ),
              SizedBox(width: 8.0),
            ],
          ),
        ),
        SizedBox(height: 4.0),
        DropTarget(
          onDragDone: _onDropFiles,
          child: _AssetDirectoryViewer(directory: null),
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
  List<AssetEntry>? _assets;
  late final StreamSubscription _subscription;

  @override
  void initState() {
    _load();
    _subscription = _s.listen((_) => _load());
    super.initState();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final assets = await AssetsApi.getAssetsInDirectory(widget.directory);
    if (!mounted) return;
    setState(() {
      _assets = assets;
    });
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
              children: _assets!
                  .map(
                    (asset) => _AssetEntryWidget(asset: asset),
                  )
                  .toList(),
            ),
          );
  }
}

class _AssetEntryWidget extends StatelessWidget {
  final AssetEntry asset;

  const _AssetEntryWidget({super.key, required this.asset});

  IconData _getIcon(AssetType type) {
    return switch (type) {
      .directory => LucideIcons.folder,
      .unsupported => LucideIcons.fileQuestionMark,
      .propertiesOnly => LucideIcons.braces,
      .texture => LucideIcons.image,
      .mesh => LucideIcons.pyramid,
      .model => LucideIcons.file,
      .shader => LucideIcons.code,
      .nodeTree => LucideIcons.listTree,
    };
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100.0,
      height: 100.0,
      child: ShadCard(
        padding: EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Icon(
                _getIcon(asset.type),
                size: 36.0,
              ),
            ),
            Text(
              asset.name,
              style: TextStyle(fontSize: 10.0),
              maxLines: 2,
              overflow: TextOverflow.fade,
            ),
          ],
        ),
      ),
    );
  }
}
