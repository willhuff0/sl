import 'dart:io';

import 'package:ffigen/ffigen.dart';

void main() {
  final packageRoot = Platform.script.resolve('../');
  FfiGenerator(
    output: Output(
      dartFile: packageRoot.resolve('lib/stb_image/stb_image.g.dart'),
      style: DynamicLibraryBindings(
        wrapperName: 'StbImageBindings',
      ),
    ),
    headers: Headers(
      entryPoints: [
        packageRoot.resolve('c_src/stb_image/stb_image.h'),
      ],
    ),
    functions: Functions.includeSet({
      'stbi_set_flip_vertically_on_load',
      'stbi_load_from_memory',
      'stbi_loadf_from_memory',
      'stbi_image_free',
    }),
  ).generate();

  final file = File(packageRoot.resolve('lib/stb_image/stb_image.g.dart').toFilePath());
  if (file.existsSync()) {
    var content = file.readAsStringSync();
    content = content.replaceAll('''import 'dart:ffi' as ffi;''', '''import 'package:wasm_ffi/ffi.dart' as ffi;''');
    file.writeAsStringSync(content);
  }
}
