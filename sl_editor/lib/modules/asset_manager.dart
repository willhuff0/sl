import 'dart:collection';

import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

abstract class Asset {
  final Uuid uuid;
  String path;
  Asset? parent;

  Asset({
    required this.uuid,
    required this.path,
    this.parent,
  });

  String getName() => p.basename(path);
  String getDirectory() => p.dirname(path);
}

class AssetManager {
  static final Set<Asset> _assets = HashSet();
  static final Map<String, Set<Asset>> _directories = {};

  static void addAsset(Asset asset) {
    _assets.add(asset);
    final directory = asset.getDirectory();
    if (_directories.containsKey(directory)) {
      _directories[directory]!.add(asset);
    } else {
      _directories[directory] = HashSet.from([asset]);
    }
  }

  static void removeAsset(Asset asset) {
    _assets.remove(asset);
    _directories[asset.getDirectory()]!.remove(asset);
  }

  static UnmodifiableSetView<Asset> getDirectory(String path) {
    return UnmodifiableSetView(_directories[path] ?? HashSet());
  }
}
