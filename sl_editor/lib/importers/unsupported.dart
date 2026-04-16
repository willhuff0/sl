import 'package:cross_file/cross_file.dart';
import 'package:path/path.dart' as p;
import 'package:sl_editor/assets.dart';
import 'package:uuid/uuid.dart';

class UnsupportedImporter {
  static Future<AssetImportResult> import(XFile file, AssetImportContext ctx) async {
    return AssetImportResult(
      consumed: {},
      createInfos: [
        AssetCreateInfo(
          uuid: Uuid().v4(),
          parent: ctx.directory,
          name: p.basenameWithoutExtension(file.name),
          type: .unsupported,
          uploadFile: file,
        ),
      ],
    );
  }
}
