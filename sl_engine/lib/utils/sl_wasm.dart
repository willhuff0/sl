import 'package:sl_wasm/sl_wasm.dart';

const slWasmPath = 'sl_wasm.wasm';

SLWasm? _slWasm;
Future<SLWasm> getSLWasm() async {
  _slWasm ??= await SLWasm.create('sl_wasm.js');
  return _slWasm!;
}
