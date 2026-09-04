import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:sl_editor/assets.dart';
import 'package:web/web.dart' as web;

final class _BrowserUploadFile implements UploadFile {
  final web.File _file;

  @override
  final String path;
  @override
  final String name;
  @override
  final String extension;

  @override
  final int size;

  _BrowserUploadFile({
    required web.File file,
    required this.path,
  }) : _file = file,
       name = p.basenameWithoutExtension(path),
       extension = p.extension(path).toLowerCase(),
       size = file.size;

  @override
  Future<Uint8List> readAsBytes() async {
    final jsBuffer = await _file.arrayBuffer().toDart;
    return jsBuffer.toDart.asUint8List();
  }

  @override
  Stream<Uint8List> openRead(int offset, int chunkSize) async* {
    var currentOffset = offset;

    while (currentOffset < size) {
      final completer = Completer<Uint8List>();
      final reader = web.FileReader();

      final end = (currentOffset + chunkSize < size) ? currentOffset + chunkSize : size;

      final slice = _file.slice(currentOffset, end);

      reader.onload = (web.Event event) {
        final JSAny? result = reader.result;
        if (result != null) {
          final jsBuffer = result as JSArrayBuffer;

          final uint8list = jsBuffer.toDart.asUint8List();
          completer.complete(uint8list);
        } else {
          completer.completeError(Exception('FileReader result was null.'));
        }
      }.toJS;

      reader.onerror = (web.Event event) {
        completer.completeError(Exception('Error reading file chunk at offset $currentOffset.'));
      }.toJS;

      reader.readAsArrayBuffer(slice);

      yield await completer.future;

      currentOffset += chunkSize;
    }
  }
}

bool _isFileDrag(web.DragEvent event) {
  final transfer = event.dataTransfer;
  if (transfer == null) {
    return false;
  }

  return transfer.types.toDart.any(
    (type) => type.toDart == 'Files',
  );
}

Future<List<web.FileSystemEntry>> _readDirectoryEntries(web.FileSystemDirectoryReader reader) async {
  final result = <web.FileSystemEntry>[];

  while (true) {
    final batch = await _readEntryBatch(reader);

    if (batch.isEmpty) {
      return result;
    }

    result.addAll(batch);
  }
}

Future<List<web.FileSystemEntry>> _readEntryBatch(web.FileSystemDirectoryReader reader) {
  final completer = Completer<List<web.FileSystemEntry>>();

  reader.readEntries(
    ((JSArray<web.FileSystemEntry> entries) {
      completer.complete(entries.toDart);
    }).toJS,
    ((web.DOMException error) {
      completer.completeError(error);
    }).toJS,
  );

  return completer.future;
}

Future<web.File> _getFile(web.FileSystemFileEntry entry) {
  final completer = Completer<web.File>();

  entry.file(
    ((web.File file) {
      completer.complete(file);
    }).toJS,
    ((web.DOMException error) {
      completer.completeError(error);
    }).toJS,
  );

  return completer.future;
}

Future<void> _walkEntry(web.FileSystemEntry entry, String parentPath, List<UploadFile> output) async {
  final relativePath = parentPath.isEmpty ? entry.name : '$parentPath/${entry.name}';

  if (entry.isFile) {
    final file = await _getFile(
      entry as web.FileSystemFileEntry,
    );

    output.add(
      _BrowserUploadFile(
        file: file,
        path: relativePath,
      ),
    );

    return;
  }

  if (entry.isDirectory) {
    final directory = entry as web.FileSystemDirectoryEntry;
    final reader = directory.createReader();

    final children = await _readDirectoryEntries(reader);

    for (final child in children) {
      await _walkEntry(
        child,
        relativePath,
        output,
      );
    }
  }
}

Future<List<_BrowserUploadFile>> _getDroppedFiles(web.DragEvent event) async {
  final transfer = event.dataTransfer;
  if (transfer == null) {
    return [];
  }

  final entries = <web.FileSystemEntry>[];

  final items = transfer.items;

  for (var i = 0; i < items.length; i++) {
    final item = items[i];

    if (item.kind != 'file') {
      continue;
    }

    final entry = item.webkitGetAsEntry();

    if (entry != null) {
      entries.add(entry);
    }
  }

  final result = <_BrowserUploadFile>[];

  for (final entry in entries) {
    await _walkEntry(entry, '', result);
  }

  return result;
}

class UploadZoneWidget extends StatefulWidget {
  final void Function(List<UploadFile> files) onDrop;
  final Widget? child;

  const UploadZoneWidget({
    super.key,
    required this.onDrop,
    this.child,
  });

  @override
  State<UploadZoneWidget> createState() => _UploadZoneWidgetState();
}

class _UploadZoneWidgetState extends State<UploadZoneWidget> {
  final dropZoneKey = GlobalKey(debugLabel: 'DropZoneKey');

  late final web.EventListener _dragOverListener;
  late final web.EventListener _dragLeaveListener;
  late final web.EventListener _dropListener;

  var _isHovered = false;

  @override
  void initState() {
    _dragOverListener = _onDragOver.toJS;
    _dragLeaveListener = _onDragLeave.toJS;
    _dropListener = _onDrop.toJS;

    web.window.addEventListener('dragover', _dragOverListener);
    web.window.addEventListener('dragleave', _dragLeaveListener);
    web.window.addEventListener('drop', _dropListener);
    super.initState();
  }

  @override
  void dispose() {
    web.window.removeEventListener('dragover', _dragOverListener);
    web.window.removeEventListener('dragleave', _dragLeaveListener);
    web.window.removeEventListener('drop', _dropListener);
    super.dispose();
  }

  void _handleDroppedFiles(web.DragEvent event) async {
    final uploadFiles = await _getDroppedFiles(event);
    widget.onDrop(uploadFiles);
  }

  bool _isInsideDropZone(double x, double y) {
    final context = dropZoneKey.currentContext;
    if (context == null) {
      return false;
    }

    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      return false;
    }

    final topLeft = box.localToGlobal(Offset.zero);
    final rect = topLeft & box.size;

    return rect.contains(Offset(x, y));
  }

  void _onDragOver(web.DragEvent event) {
    if (!_isFileDrag(event)) return;

    final isInside = _isInsideDropZone(
      event.clientX.toDouble(),
      event.clientY.toDouble(),
    );

    event.preventDefault();

    event.dataTransfer!.dropEffect = isInside ? 'copy' : 'none';
    setState(() => _isHovered = isInside);
  }

  void _onDragLeave(web.DragEvent event) {
    setState(() => _isHovered = false);
  }

  void _onDrop(web.DragEvent event) {
    if (!_isFileDrag(event)) return;

    event.preventDefault();

    final isInside = _isInsideDropZone(
      event.clientX.toDouble(),
      event.clientY.toDouble(),
    );

    setState(() => _isHovered = false);

    if (isInside) {
      _handleDroppedFiles(event);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: dropZoneKey,
      fit: .expand,
      children: [
        if (widget.child != null) widget.child!,
        AnimatedOpacity(
          duration: Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          opacity: _isHovered ? 1.0 : 0.0,
          child: _DropHintWidget(),
        ),
      ],
    );
  }
}

class _DropHintWidget extends StatelessWidget {
  const _DropHintWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
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
    );
  }
}
