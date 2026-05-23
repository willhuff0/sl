import 'dart:io';

import 'package:ffigen/ffigen.dart';

void main() {
  final packageRoot = Platform.script.resolve('../');
  final functions = File(packageRoot.resolve('c_src/bullet3/exports.txt').toFilePath())
      .readAsStringSync()
      .split('\n')
      .skip(2)
      .map(
        (line) => line.substring(1),
      )
      .toSet();
  FfiGenerator(
    output: Output(
      dartFile: packageRoot.resolve('lib/bullet3/bullet3.g.dart'),
      style: DynamicLibraryBindings(
        wrapperName: 'StbImageBullet3Bindings',
      ),
    ),
    typedefs: Typedefs.includeAll,
    headers: Headers(
      entryPoints: [
        packageRoot.resolve('c_src/bullet3/bullet3.h'),
      ],
    ),
    functions: Functions.includeSet(functions),
  ).generate();

  final file = File(packageRoot.resolve('lib/bullet3/bullet3.g.dart').toFilePath());
  if (file.existsSync()) {
    var content = file.readAsStringSync();
    content = content.replaceAll('''import 'dart:ffi' as ffi;''', '''import 'package:wasm_ffi/ffi.dart' as ffi;''');
    file.writeAsStringSync(content);
  }
}
