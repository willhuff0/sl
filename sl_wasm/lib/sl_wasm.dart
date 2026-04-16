library;

import 'package:sl_wasm/stb_image.dart';
import 'package:wasm_ffi/ffi.dart';

class SLWasm {
  final StbImage stbImage;

  SLWasm._(DynamicLibrary library) : stbImage = StbImage(library);

  static Future<SLWasm> create(String libPath) async {
    final library = await DynamicLibrary.open(
      libPath,
      moduleName: 'SLWasm',
      wasmType: WasmType.wasm32Emscripten,
    );
    return SLWasm._(library);
  }
}
