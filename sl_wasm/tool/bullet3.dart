import 'dart:io';

import 'package:ffigen/ffigen.dart';

void main() {
  final packageRoot = Platform.script.resolve('../');
  FfiGenerator(
    output: Output(
      dartFile: packageRoot.resolve('lib/bullet3/bullet3.g.dart'),
      style: DynamicLibraryBindings(
        wrapperName: 'StbImageBullet3Bindings',
      ),
    ),
    headers: Headers(
      entryPoints: [
        packageRoot.resolve('c_src/bullet3/bullet3.h'),
      ],
    ),
    functions: Functions.includeSet({
      '',
    }),
  ).generate();

  final file = File(packageRoot.resolve('lib/bullet3/bullet3.g.dart').toFilePath());
  if (file.existsSync()) {
    var content = file.readAsStringSync();
    content = content.replaceAll('''import 'dart:ffi' as ffi;''', '''import 'package:wasm_ffi/ffi.dart' as ffi;''');
    file.writeAsStringSync(content);
  }
}
