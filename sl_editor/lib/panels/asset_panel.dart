import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:sl_editor/client/assets_api.dart';
import 'package:sl_editor/client/client.dart';
import 'package:sl_engine/editor/sl_editor.dart';
import 'package:sl_engine/gl/gltf_loader.dart';
import 'package:sl_engine/logger.dart';
import 'package:sl_engine/utils/resource_loader.dart';
import 'package:sl_shared/sl_shared.dart';
import 'package:image/image.dart' as img;

class AssetPanel extends StatelessWidget {
  const AssetPanel({super.key});

  void _onDropFiles(DropDoneDetails details) async {
    await AssetsApi.addAssets(null, details.files);
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
                  // ShadBreadcrumbDropMenuItem(
                  //   child: Text('Test Asset'),
                  //   onPressed: () async {
                  //     await AssetsApi.createAsset(null, 'Test Asset', AssetType.mesh);
                  //   },
                  // ),
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
    _subscription = watchAssetsInDirectory(Client.get().assetSystem.sharedDatabase, widget.directory).listen((event) {
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
              children: _foldedAssets!
                  .map(
                    (foldedAsset) => _AssetEntryWidget(asset: _assets![foldedAsset.uuid]!),
                  )
                  .toList(),
            ),
          );
  }
}

class _AssetEntryWidget extends StatelessWidget {
  final Asset asset;

  const _AssetEntryWidget({super.key, required this.asset});

  Widget _getPreview(AssetType type) {
    return switch (type) {
      .directory => Icon(LucideIcons.folder),
      .unsupported => Icon(LucideIcons.fileQuestionMark),
      .propertiesOnly => Icon(LucideIcons.braces),
      .texture => _ImageAssetPreviewWidget(asset: asset),
      .mesh => Icon(LucideIcons.pyramid),
      .model => _ModelAssetPreviewWidget(asset: asset),
      .shader => Icon(LucideIcons.code),
      .nodeTree => Icon(LucideIcons.listTree),
    };
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 1024.0,
      height: 1024.0,
      child: ShadCard(
        padding: EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _getPreview(asset.type),
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

class _ImageAssetPreviewWidget extends StatefulWidget {
  final Asset asset;

  const _ImageAssetPreviewWidget({super.key, required this.asset});

  @override
  State<_ImageAssetPreviewWidget> createState() => _ImageAssetPreviewWidgetState();
}

class _ImageAssetPreviewWidgetState extends State<_ImageAssetPreviewWidget> {
  Uint8List? _data;

  @override
  void initState() {
    _load();
    super.initState();
  }

  void _load() async {
    final data = await Client.get().assetSystem.getAssetBlob(widget.asset.uuid);
    if (mounted) {
      setState(() {
        _data = data;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(4.0),
      child: _data == null ? Center(child: CircularProgressIndicator()) : Image.memory(_data!),
    );
  }
}

class StubResourceLoader implements ResourceLoader {
  final Uint8List bytes;

  StubResourceLoader(this.bytes);

  @override
  Future<Uint8List?> loadBytes(String path) async {
    return bytes;
  }

  @override
  Future<String?> loadString(String path) async {
    return utf8.decode(bytes);
  }
}

class _ModelAssetPreviewWidget extends StatefulWidget {
  final Asset asset;

  const _ModelAssetPreviewWidget({super.key, required this.asset});

  @override
  State<_ModelAssetPreviewWidget> createState() => __ModelAssetPreviewWidgetState();
}

class __ModelAssetPreviewWidgetState extends State<_ModelAssetPreviewWidget> {
  late final StreamSubscription _assetBlobSubscription;
  Uint8List? _data;

  void initState() {
    _assetBlobSubscription = Client.get().assetSystem.watchAssetBlob(widget.asset.uuid).listen((bytes) async {
      if (bytes == null) {
        if (mounted) {
          setState(() {
            _data = null;
          });
        }
        return;
      }

      final gltf = await GLTF.load('stub.glb', resourceLoader: StubResourceLoader(bytes));
      if (gltf == null) {
        Logger.log(
          'Failed to parse glb while generating model preview for ${widget.asset.name} (${widget.asset.uuid})',
        );
        return;
      }

      while (SLEditor.modelPreviewGenerator == null) {
        await Future.delayed(Duration(milliseconds: 100));
      }
      final raw = SLEditor.modelPreviewGenerator!.generateModelPreview(gltf.root, size: 1024);
      if (raw.isEmpty) return;
      final image = img.Image.fromBytes(width: 1024, height: 1024, bytes: raw.buffer, numChannels: 4);
      final data = img.encodePng(image);

      if (mounted) {
        setState(() {
          _data = data;
        });
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _assetBlobSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(4.0),
      child: _data == null ? Center(child: CircularProgressIndicator()) : Image.memory(_data!),
    );
  }
}
