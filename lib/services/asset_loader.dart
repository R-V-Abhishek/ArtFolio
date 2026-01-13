import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class AssetLoader {
  // Loads a JSON file from assets and returns a list. Accepts either a top-level
  // JSON array or an object with an `items` array.
  static Future<List<dynamic>> loadJsonList(String path) async {
    final text = await rootBundle.loadString(path);
    final data = jsonDecode(text);
    if (data is List) return data;
    if (data is Map && data['items'] is List) return List.from(data['items']);
    return [];
  }
}
