import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:sl_engine/logger.dart';

bool _isHtmlFile(String body) {
  body = body.trimLeft();
  return body.startsWith('<!DOCTYPE html>') || body.startsWith('<html>');
}

class ResourceLoader {
  static Uri getUri(String path) {
    return Uri.parse(p.join('resources', path));
  }

  static Future<http.Response?> load(String path) async {
    final uri = getUri(path);
    final response = await http.get(uri);
    if (response.statusCode == 404) {
      Logger.log('Tried to load a resource \'$path\' which does not exist. HTTP GET to \'$uri\' returned status code ${response.statusCode}.', .warning);
      return null;
    } else if (response.statusCode != 200) {
      Logger.log('Failed to to load a resource \'$path\'. HTTP GET to \'$uri\' returned status code ${response.statusCode}.', .warning);
      return null;
    } else if (_isHtmlFile(response.body)) {
      Logger.log('Tried to load a resource \'$path\' which does not exist.', .warning);
      return null;
    }
    return response;
  }

  static Future<String?> loadString(String path) async {
    return (await load(path))?.body;
  }

  static Future<Uint8List?> loadBytes(String path) async {
    return (await load(path))?.bodyBytes;
  }
}
