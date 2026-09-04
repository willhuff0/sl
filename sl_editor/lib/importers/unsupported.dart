import 'package:sl_editor/assets.dart';
import 'package:uuid/uuid.dart';

class UnsupportedImporter {
  static Future<AssetImportResult> import(UploadFile file, AssetImportContext ctx) async {
    return AssetImportResult(
      consumed: {},
      createInfos: [
        AssetCreateInfo(
          uuid: Uuid().v4(),
          parent: ctx.directory,
          name: file.name,
          type: .unsupported,
          uploadFile: file,
        ),
      ],
    );
  }
}
