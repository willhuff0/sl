import 'package:sl_server/assets/asset.dart';
import 'package:sl_server/assets/node_asset.dart';

abstract class ModelParser {
  List<String> getSupportedFileTypes();

  Future<(NodeAsset root, List<Asset>)> parse(String path);
}
