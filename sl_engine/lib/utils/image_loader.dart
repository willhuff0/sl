import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

const stbImageWasmPath = 'stb_image.wasm';

typedef Pointer = int;

class _StbImageLibrary {
  final void Function(int flagTrueIfShouldFlip) setFlipVerticallyOnLoad;
  final Pointer Function(Pointer buf, int len, Pointer x, Pointer y, Pointer channelsInFile, int desiredChannels) loadfFromMemory;
  final void Function(Pointer retValFromStbiLoad) imageFree;

  final Pointer Function(int size) malloc;
  final web.Memory memory;
  final ByteBuffer memoryBuffer;

  _StbImageLibrary({
    required this.setFlipVerticallyOnLoad,
    required this.loadfFromMemory,
    required this.imageFree,
    required this.malloc,
    required this.memory,
  }) : memoryBuffer = memory.buffer.toDart;
}

_StbImageLibrary? _library;
Future<_StbImageLibrary> _getLibrary() async {
  _library ??= await web.WebAssembly.instantiateStreaming(web.window.fetch(stbImageWasmPath.toJS)).toDart.then((wasm) {
    final exports = wasm.instance.exports.dartify() as dynamic;
    final memory = exports.memory as web.Memory;
    // memory.grow(10);
    return _StbImageLibrary(
      setFlipVerticallyOnLoad: exports.stbi_set_flip_vertically_on_load,
      loadfFromMemory: exports.stbi_loadf_from_memory,
      imageFree: exports.stbi_image_free,
      malloc: exports.malloc,
      memory: memory,
    );
  });
  return _library!;
}

class ImageLoader {
  static Future<Uint8List> loadHdri(Uint8List raw) async {
    final library = await _getLibrary();

    final buffer = library.malloc(raw.length);
    Uint8List.view(library.memoryBuffer, buffer, raw.length).setAll(0, raw);
    final x = library.malloc(4);
    final y = library.malloc(4);

    library.setFlipVerticallyOnLoad(1);
    final pixels = library.loadfFromMemory(buffer, raw.length, x, y, 0, 4);
    library.setFlipVerticallyOnLoad(0);

    final width = Uint32List.view(library.memoryBuffer);

    final imageData = Uint8List()
  }
}
