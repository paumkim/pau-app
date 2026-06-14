import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Caches translations locally so they work offline.
/// Every translation is stored with a key: "sourceLang:targetLang:normalizedText"
/// Future lookups check the cache first, then fall back to API.
class TranslationCache {
  static const _cacheKey = 'translation_cache';
  static Map<String, String>? _cache;

  static Future<void> _ensureLoaded() async {
    if (_cache != null) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw != null) {
      _cache = Map<String, String>.from(jsonDecode(raw));
    } else {
      _cache = {};
    }
  }

  static String _buildKey(String text, String source, String target) {
    final normalized = text.toLowerCase().trim();
    return '$source:$target:$normalized';
  }

  /// Try to get a cached translation.
  static Future<String?> get(String text, String source, String target) async {
    await _ensureLoaded();
    return _cache![_buildKey(text, source, target)];
  }

  /// Store a translation in cache.
  static Future<void> set(String text, String source, String target, String translation) async {
    await _ensureLoaded();
    _cache![_buildKey(text, source, target)] = translation;
    await _persist();
  }

  /// Get all saved vocabulary entries (for the vocab builder).
  static Future<List<Map<String, String>>> getAllEntries() async {
    await _ensureLoaded();
    final entries = <Map<String, String>>[];
    for (final entry in _cache!.entries) {
      final parts = entry.key.split(':');
      if (parts.length == 3) {
        entries.add({
          'sourceText': parts[2],
          'sourceLanguage': parts[0],
          'targetLanguage': parts[1],
          'translatedText': entry.value,
        });
      }
    }
    return entries;
  }

  /// Get vocabulary entries for a specific language pair.
  static Future<List<Map<String, String>>> getEntriesForPair(
    String source, String target,
  ) async {
    final all = await getAllEntries();
    return all.where((e) =>
      e['sourceLanguage'] == source && e['targetLanguage'] == target
    ).toList();
  }

  /// Search cached translations.
  static Future<List<Map<String, String>>> search(String query) async {
    final q = query.toLowerCase();
    final all = await getAllEntries();
    return all.where((e) =>
      e['sourceText']!.toLowerCase().contains(q) ||
      e['translatedText']!.toLowerCase().contains(q)
    ).toList();
  }

  static Future<void> clear() async {
    _cache = {};
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
  }

  static Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(_cache));
  }

  static Future<int> get count async {
    await _ensureLoaded();
    return _cache!.length;
  }
}
