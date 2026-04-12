import 'dart:js_interop';

import 'package:web/web.dart';

class SlFileSystem {
  static late FileSystemDirectoryHandle root;

  static Future<void> init(String projectId) async {
    final originPrivateFileSystem = await window.navigator.storage.getDirectory().toDart;
    root = await originPrivateFileSystem
        .getDirectoryHandle(
          projectId,
          FileSystemGetDirectoryOptions(
            create: true,
          ),
        )
        .toDart;
  }
}
