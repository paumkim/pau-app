import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'translation_cache.dart';

enum TranslationMode { cloud, local, fallback }

class TranslationResult {
  final String text;
  final bool success;
  final String? error;

  TranslationResult({required this.text, required this.success, this.error});
}

class TranslationService {
  TranslationMode _mode = TranslationMode.cloud;

  Future<TranslationResult> translate({
    required String text,
    required String source,
    required String target,
  }) async {
    if (text.trim().isEmpty) {
      return TranslationResult(text: '', success: false, error: 'No text to translate');
    }

    // Check cache first
    final cached = await TranslationCache.get(text, source, target);
    if (cached != null) {
      return TranslationResult(
        text: cached,
        success: true,
        error: 'Cached translation',
      );
    }

    try {
      TranslationResult result;
      switch (_mode) {
        case TranslationMode.cloud:
          result = await _translateCloud(text, source, target);
          break;
        case TranslationMode.local:
          result = await _translateLocal(text, source, target);
          break;
        case TranslationMode.fallback:
          result = _fallbackTranslate(text);
          break;
      }

      // Cache successful translations
      if (result.success && result.text != text) {
        await TranslationCache.set(text, source, target, result.text);
      }

      return result;
    } on TimeoutException {
      return TranslationResult(
        text: text, success: false,
        error: 'Translation timed out. Check your connection.',
      );
    } on http.ClientException catch (e) {
      return TranslationResult(
        text: text, success: false,
        error: 'Network error: ${e.message}',
      );
    } catch (e) {
      debugPrint('Translation error: $e');
      return TranslationResult(
        text: text, success: false,
        error: 'Translation failed. Try again.',
      );
    }
  }

  Future<TranslationResult> _translateCloud(String text, String source, String target) async {
    final response = await http.post(
      Uri.parse('${AppConfig.cloudApiBase}/translate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'text': text, 'source': source, 'target': target}),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final translated = data['translated_text'] as String?;
      if (translated != null && translated.isNotEmpty) {
        return TranslationResult(text: translated, success: true);
      }
    }
    // Cloud unavailable — fall through to fallback
    return _fallbackTranslate(text);
  }

  Future<TranslationResult> _translateLocal(String text, String source, String target) async {
    final response = await http.post(
      Uri.parse('http://localhost:8080/translate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'text': text, 'source': source, 'target': target}),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final translated = data['translation'] as String?;
      if (translated != null && translated.isNotEmpty) {
        return TranslationResult(text: translated, success: true);
      }
    }
    return _fallbackTranslate(text);
  }

  TranslationResult _fallbackTranslate(String text) {
    return TranslationResult(
      text: text,
      success: true,
      error: 'Cloud translation unavailable. Showing original text.',
    );
  }

  String detectLanguage(String text) {
    final zomiMarkers = [
      'hi', 'leh', 'tawh', 'sung', 'bang', 'ciang', 'khin',
      'ding', 'mah', 'zong', 'kei', 'nang', 'hih', 'hua'
    ];
    final words = text.toLowerCase().split(' ');
    final zomiScore = zomiMarkers.where((m) => words.contains(m)).length;

    if (zomiScore >= 2) return 'zomi';
    if (RegExp(r'[\u4e00-\u9fff]').hasMatch(text)) return 'zh';
    if (RegExp(r'[a-zA-Z]').hasMatch(text)) return 'en';
    return 'ms';
  }

  String getLanguageName(String code) {
    switch (code) {
      case 'zomi': return 'Zomi';
      case 'en': return 'English';
      case 'ms': return 'Malay';
      case 'zh': return 'Chinese';
      default: return code;
    }
  }
}
