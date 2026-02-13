// import 'dart:convert';
// import 'dart:io';
//
// import 'package:path/path.dart' as p;
// import 'package:sl_server/assets/asset.dart';
// import 'package:sl_server/assets/node_asset.dart';
//
// import 'model_parser.dart';
//
// class GltfParser extends ModelParser {
//   @override
//   List<String> getSupportedFileTypes() => [
//     '.gltf',
//     '.glb',
//   ];
//
//   @override
//   Future<(NodeAsset root, List<Asset>)> parse(String path) async {
//     switch (p.extension(path)) {
//       case '.gltf':
//         return _parseGltf(path);
//         break;
//       case '.glb':
//         // TODO
//         throw Exception('TODO');
//       default:
//         throw Exception('$GltfParser cannot parse this file type: ${p.extension(path)}');
//     }
//   }
//
//   Future<(NodeAsset root, List<Asset>)> _parseGltf(String path) async {
//     final json = jsonDecode(await File(path).readAsString()) as Map<String, dynamic>;
//   }
// }
