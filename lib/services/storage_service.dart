import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/translation.dart';

class StorageService {
  static const _historyKey = 'translation_history';

  Future<void> saveTranslation(Translation translation) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();
    history.insert(0, translation);

    final jsonList = history.map((t) => t.toJson()).toList();
    await prefs.setString(_historyKey, jsonEncode(jsonList));
  }

  Future<List<Translation>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_historyKey);
    if (json == null) return [];

    final list = jsonDecode(json) as List;
    return list.map((e) => Translation.fromJson(e)).toList();
  }

  Future<void> toggleFavorite(String id) async {
    final history = await getHistory();
    for (var t in history) {
      if (t.id == id) {
        t.isFavorite = !t.isFavorite;
        break;
      }
    }
    final prefs = await SharedPreferences.getInstance();
    final jsonList = history.map((t) => t.toJson()).toList();
    await prefs.setString(_historyKey, jsonEncode(jsonList));
  }

  Future<List<Translation>> getFavorites() async {
    final history = await getHistory();
    return history.where((t) => t.isFavorite).toList();
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }
}
