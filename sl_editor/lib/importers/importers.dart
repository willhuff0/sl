import 'package:sl_editor/assets.dart';
import 'package:sl_editor/importers/archive.dart';
import 'package:sl_editor/importers/gltf.dart';

void registerImporters() {
  Assets.registerImporter(ArchiveImporter.registration);
  Assets.registerImporter(GLTFImporter.registration);
}
