import 'package:cross_file/cross_file.dart';
import 'package:path/path.dart' as p;
import 'package:sl_editor/client/client.dart';
import 'package:sl_shared/sl_shared.dart';
import 'package:uuid/uuid.dart';

const _extensionToAssetType = <String, AssetType>{
  '.jpg': .texture,
  '.jpeg': .texture,
  '.png': .texture,
  '.gltf': .model,
  '.glb': .model,
};

class AssetsApi {
  static Future<void> addAssets(UUID? directory, List<XFile> files) async {
    final database = Client.get().assetSystem.database;

    final parent = directory;
    final updatedAt = DateTime.now().toIso8601String();
    final blobUpdatedAt = updatedAt;

    final arguments = [];
    final uuidToFile = <UUID, XFile>{};
    for (final file in files) {
      final uuid = Uuid().v4();
      final name = file.name;
      final type = (_extensionToAssetType[p.extension(file.name).toLowerCase()] ?? .unsupported).name;
      arguments.addAll([uuid, parent, name, type, updatedAt, blobUpdatedAt]);
      uuidToFile[uuid] = file;
    }

    print(arguments);

    await database.execute('''
INSERT INTO assets (uuid, parent, name, type, updated_at, blob_updated_at)
VALUES
  ${List.generate(files.length, (i) => '  (?${i + 1}, ?${i + 2}, ?${i + 3}, ?${i + 4}, ?${i + 5}, ?${i + 6})').join(',\n')};
''', arguments);

    for (final entry in uuidToFile.entries) {
      final uuid = entry.key;
      final file = entry.value;
      await Client.get().assetSystem.uploadAssetBlob(uuid, file);
    }
  }
}
