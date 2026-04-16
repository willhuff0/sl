import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

void downloadBlobToDevice(web.Blob blob, {String filename = 'download'}) {
  final url = web.URL.createObjectURL(blob);

  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = url;
  anchor.download = filename;
  anchor.click();
  anchor.remove();

  web.URL.revokeObjectURL(url);
}

void downloadBytesToDevice(Uint8List bytes, {String filename = 'download'}) {
  downloadBlobToDevice(web.Blob([bytes.toJS].toJS), filename: filename);
}
