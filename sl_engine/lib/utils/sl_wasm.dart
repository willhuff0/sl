import 'package:sl_wasm/stb_image/stb_image.dart';

StbImage? _stbImage;
Future<StbImage> getStbImage() async {
  _stbImage ??= await StbImage.create('sl_wasm.js');
  return _stbImage!;
}
