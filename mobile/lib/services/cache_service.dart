import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  static const String _boxName = 'petid_api_cache';
  Box? _box;

  /// Initializes the local secure NoSQL hive storage engine.
  Future<void> initialize() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
  }

  /// Caches the dynamic JSON response mapped statically to a URL Endpoint String Key.
  Future<void> save(String endpoint, dynamic jsonResponse) async {
    if (_box == null) return;
    
    try {
      // Stringify before saving so we don't worry about complex Dart Map tree caching issues
      final String serialized = jsonEncode(jsonResponse);
      await _box!.put(endpoint, serialized);
    } catch (e) {
      print('Erro ao salvar cache: $e');
    }
  }

  /// Retrieves the JSON payload instantly from RAM/Disk NoSQL bounds.
  dynamic get(String endpoint) {
    if (_box == null) return null;
    
    try {
      final String? cached = _box!.get(endpoint);
      if (cached != null) {
        return jsonDecode(cached);
      }
    } catch (e) {
      print('Erro ao ler cache: $e');
    }
    return null;
  }

  /// Purges all local intercepted server responses from local storage.
  Future<void> clearAll() async {
    if (_box != null) {
      await _box!.clear();
    }
  }
}
