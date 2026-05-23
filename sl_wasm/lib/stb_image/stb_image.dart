import 'dart:typed_data';

import 'package:wasm_ffi/ffi.dart';
import 'package:wasm_ffi/ffi_utils.dart';
import 'stb_image.g.dart';

class StbImage {
  final DynamicLibrary _library;
  final StbImageBindings _bindings;

  StbImage._(this._library) : _bindings = StbImageBindings(_library);

  static Future<StbImage> create(String libPath) async {
    return StbImage._(
      await DynamicLibrary.open(
        libPath,
        moduleName: 'SLWasm',
        wasmType: WasmType.wasm32Emscripten,
      ),
    );
  }

  (Uint8List bytes, int width, int height, int channels) loadFromMemory(Uint8List encodedBytes, {int? channels}) {
    return using((Arena arena) {
      final encodedBuffer = arena.allocate<Uint8>(encodedBytes.length);
      encodedBuffer.asTypedList(encodedBytes.length).setAll(0, encodedBytes);

      final xOut = arena.allocate<Int>(4);
      final yOut = arena.allocate<Int>(4);
      final channelsOut = arena.allocate<Int>(4);

      final pixels = _bindings.stbi_load_from_memory(encodedBuffer, encodedBytes.length, xOut, yOut, channelsOut, channels ?? 0);

      final width = xOut.cast<Uint32>().value;
      final height = yOut.cast<Uint32>().value;
      final actualChannels = channelsOut.cast<Uint32>().value;

      final dartPixels = Uint8List.fromList(pixels.asTypedList(width * height * (channels ?? actualChannels)));
      _bindings.stbi_image_free(pixels.cast());

      return (dartPixels, width, height, channels ?? actualChannels);
    }, _library.allocator);
  }

  (Float32List floats, int width, int height, int channels) loadfFromMemory(Uint8List encodedBytes, {int? channels}) {
    return using((Arena arena) {
      final encodedBuffer = arena.allocate<Uint8>(encodedBytes.length);
      encodedBuffer.asTypedList(encodedBytes.length).setAll(0, encodedBytes);

      final xOut = arena.allocate<Int>(4);
      final yOut = arena.allocate<Int>(4);
      final channelsOut = arena.allocate<Int>(4);

      _bindings.stbi_set_flip_vertically_on_load(1);
      final pixels = _bindings.stbi_loadf_from_memory(encodedBuffer, encodedBytes.length, xOut, yOut, channelsOut, channels ?? 0);
      _bindings.stbi_set_flip_vertically_on_load(0);

      final width = xOut.cast<Uint32>().value;
      final height = yOut.cast<Uint32>().value;
      final actualChannels = channelsOut.cast<Uint32>().value;

      final dartPixels = Float32List.fromList(pixels.asTypedList(width * height * (channels ?? actualChannels)));
      _bindings.stbi_image_free(pixels.cast());

      return (dartPixels, width, height, channels ?? actualChannels);
    }, _library.allocator);
  }
}
