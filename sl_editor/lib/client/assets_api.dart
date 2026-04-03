import 'dart:async';
import 'dart:typed_data';

import 'package:sl_editor/client/client.dart';
import 'package:sl_shared/sl_shared.dart';

class AssetTransferProgress {
  final int byteSize;
  final int bytesCompleted;
  final double progress;

  AssetTransferProgress({
    required this.byteSize,
    required this.bytesCompleted,
    required this.progress,
  });
}

class AssetTransferOperation {
  final UUID uuid;
  final int byteSize;

  final BytesBuilder _data = BytesBuilder();

  late final Completer<Uint8List> _completer = Completer();

  final _progressController = StreamController<AssetTransferProgress>.broadcast();
  late final Stream<AssetTransferProgress> progressStream;

  AssetTransferOperation({required this.uuid, required this.byteSize}) {
    progressStream = _progressController.stream;
  }

  Future<Uint8List> get onComplete => _completer.future;

  void addData(Uint8List newData) {
    if (_completer.isCompleted) return;
    if (_data.length + newData.length > byteSize) throw Exception('Asset Transfer Byte Buffer overflowed');

    _data.add(newData);
    _progressController.add(
      AssetTransferProgress(
        byteSize: byteSize,
        bytesCompleted: _data.length,
        progress: byteSize / _data.length,
      ),
    );
    if (_data.length == byteSize) {
      _completer.complete(_data.toBytes());
      _progressController.close();
    }
  }
}

class AssetsApi {
  static final Map<UUID, AssetTransferOperation> _downloads = {};
  // static final Map<UUID, AssetTransferOperation> _uploads = {};

  static Future<List<AssetEntry>> getAssetsInDirectory(UUID? directory) async {
    return (await Client.get().rpc.callRemoteMethod('getAssetsInDirectory', directory) as List)
        .map(
          (json) => AssetEntry.fromJson(json),
        )
        .toList();
  }

  static Future<AssetEntry> createAsset(UUID? parent, String name, AssetType type) async {
    final uuid = await Client.get().rpc.callRemoteMethod('createAsset', {
      'parent': ?parent,
      'name': name,
      'type': type.index,
    });

    return AssetEntry(
      uuid: uuid,
      name: name,
      type: type,
      subAssets: [],
      blobSize: 0,
    );
  }

  static Future<void> deleteAsset(UUID uuid) async {
    await Client.get().rpc.callRemoteMethod('deleteAsset', uuid);
  }

  // static Future<AssetTransferOperation> setAssetData(UUID uuid, Uint8List data) async {
  //   var operation = _uploads[uuid];
  //   if (operation != null) return operation;

  //   operation = _uploads[uuid] = AssetTransferOperation(
  //     uuid: uuid,
  //     byteSize: data.length,
  //   );
  //   operation.onComplete.then((_) {
  //     _uploads.remove(uuid);
  //   });

  //   final allowed = await Client.get().rpc.callRemoteMethod('setAssetData', uuid);
  //   if (!allowed) {
  //     // TODO: error
  //   }

  //   return operation;
  // }

  static Future<AssetTransferOperation> getAssetData(UUID uuid) async {
    // TODO: cache in browser

    var operation = _downloads[uuid];
    if (operation != null) return operation;

    final size = await Client.get().rpc.callRemoteMethod('getAssetData', uuid);
    if (size == 0) {
      // TODO: error
    }

    operation = _downloads[uuid] = AssetTransferOperation(
      uuid: uuid,
      byteSize: size,
    );

    return operation;
  }
}
