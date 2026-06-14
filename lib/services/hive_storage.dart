import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HiveStorage {
  static const _chatBox = 'chat_history';
  static const _translationBox = 'translation_history';
  static const _bookmarksBox = 'bookmarks';
  static const _readingProgressBox = 'reading_progress';

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      await Hive.initFlutter();
      await Hive.openBox(_chatBox);
      await Hive.openBox(_translationBox);
      await Hive.openBox(_bookmarksBox);
      await Hive.openBox(_readingProgressBox);
      _initialized = true;
      debugPrint('Hive initialized successfully');
    } catch (e) {
      debugPrint('Hive init failed, falling back to SharedPreferences: $e');
    }
  }

  static bool get isAvailable => _initialized;

  // Chat history
  static Box get _chat => Hive.box(_chatBox);
  static Box get _trans => Hive.box(_translationBox);
  static Box get _bookmarks => Hive.box(_bookmarksBox);
  static Box get _progress => Hive.box(_readingProgressBox);

  static Future<void> saveChatMessage(Map<String, dynamic> message) async {
    if (!_initialized) {
      await _legacySaveChat(message);
      return;
    }
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    await _chat.put(id, message);
  }

  static Future<List<Map<String, dynamic>>> getChatHistory() async {
    if (!_initialized) return _legacyGetChat();
    return _chat.values.cast<Map<String, dynamic>>().toList()
      ..sort((a, b) => (b['time'] ?? '').compareTo(a['time'] ?? ''));
  }

  static Future<void> clearChatHistory() async {
    if (!_initialized) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('pau_chat_history');
      return;
    }
    await _chat.clear();
  }

  static Future<void> deleteChatMessage(String id) async {
    if (!_initialized) return;
    await _chat.delete(id);
  }

  // Translation history
  static Future<void> saveTranslation(Map<String, dynamic> translation) async {
    if (!_initialized) return;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    await _trans.put(id, translation);
  }

  static Future<List<Map<String, dynamic>>> getTranslationHistory() async {
    if (!_initialized) return [];
    return _trans.values.cast<Map<String, dynamic>>().toList()
      ..sort((a, b) => (b['timestamp'] ?? '').compareTo(a['timestamp'] ?? ''));
  }

  static Future<void> clearTranslationHistory() async {
    if (!_initialized) return;
    await _trans.clear();
  }

  // Bookmarks
  static Future<void> saveBookmark(String bookId, Map<String, dynamic> bookmark) async {
    if (!_initialized) return;
    await _bookmarks.put('${bookId}_${bookmark['section']}_${bookmark['chapter']}', bookmark);
  }

  static Future<List<Map<String, dynamic>>> getBookmarks(String bookId) async {
    if (!_initialized) return [];
    return _bookmarks.values
        .where((b) => (b['bookId'] ?? '') == bookId)
        .cast<Map<String, dynamic>>()
        .toList();
  }

  static Future<void> removeBookmark(String key) async {
    if (!_initialized) return;
    await _bookmarks.delete(key);
  }

  // Reading progress
  static Future<void> saveProgress(String bookId, int section, int chapter) async {
    if (!_initialized) return;
    await _progress.put(bookId, {'section': section, 'chapter': chapter, 'updatedAt': DateTime.now().toIso8601String()});
  }

  static Future<Map<String, dynamic>?> getProgress(String bookId) async {
    if (!_initialized) return null;
    final data = _progress.get(bookId);
    return data as Map<String, dynamic>?;
  }

  // Legacy migration helpers (read from SharedPreferences and write to Hive)
  static Future<void> migrateFromSharedPreferences() async {
    if (!_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();

      // Migrate chat history
      final chatRaw = prefs.getString('pau_chat_history');
      if (chatRaw != null && _chat.isEmpty) {
        final list = jsonDecode(chatRaw) as List;
        for (var msg in list) {
          final id = DateTime.now().millisecondsSinceEpoch.toString();
          await _chat.put(id, msg as Map<String, dynamic>);
        }
        debugPrint('Migrated ${list.length} chat messages to Hive');
      }

      // Migrate translation history
      final transRaw = prefs.getString('translation_history');
      if (transRaw != null && _trans.isEmpty) {
        final list = jsonDecode(transRaw) as List;
        for (var t in list) {
          final id = DateTime.now().millisecondsSinceEpoch.toString();
          await _trans.put(id, t as Map<String, dynamic>);
        }
        debugPrint('Migrated ${list.length} translations to Hive');
      }
    } catch (e) {
      debugPrint('Migration error: $e');
    }
  }

  // Legacy SharedPreferences fallbacks
  static Future<void> _legacySaveChat(Map<String, dynamic> message) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('pau_chat_history');
    final list = raw != null ? (jsonDecode(raw) as List).cast<Map<String, dynamic>>() : <Map<String, dynamic>>[];
    list.add(message);
    await prefs.setString('pau_chat_history', jsonEncode(list));
  }

  static Future<List<Map<String, dynamic>>> _legacyGetChat() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('pau_chat_history');
    if (raw == null) return [];
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }
}
