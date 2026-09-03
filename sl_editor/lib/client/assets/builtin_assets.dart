import 'package:sl_shared/sl_shared.dart';

class BuiltinAsset {
  final Asset mockDatabaseAsset;
  final String? blobPath;
  final String? thumbPath;

  BuiltinAsset({
    required this.mockDatabaseAsset,
    required this.blobPath,
    required this.thumbPath,
  });
}

final builtinAssets = {
  '&skybox': BuiltinAsset(
    mockDatabaseAsset: Asset(
      uuid: '&skybox',
      parent: null,
      name: 'Skybox',
      type: .hdri,
      properties: null,
      updatedAt: DateTime(2026, 7, 12, 13, 11),
      blobSize: null,
      blobVersion: 1,
      thumbMime: null,
    ),
    blobPath: 'skybox_02_OH_NO.hdr',
    thumbPath: null,
  ),
};
