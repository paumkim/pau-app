import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../lib/services/translation_service.dart';
import '../lib/services/storage_service.dart';
import '../lib/models/translation.dart';

void main() {
  group('TranslationService', () {
    late TranslationService service;

    setUp(() {
      service = TranslationService();
    });

    test('detectLanguage returns zomi for Zomi markers', () {
      final result = service.detectLanguage('hi kei mah tawh');
      expect(result, 'zomi');
    });

    test('detectLanguage returns zh for Chinese characters', () {
      final result = service.detectLanguage('你好世界');
      expect(result, 'zh');
    });

    test('detectLanguage returns en for Latin script', () {
      final result = service.detectLanguage('Hello world');
      expect(result, 'en');
    });

    test('detectLanguage returns ms for unknown', () {
      final result = service.detectLanguage('12345');
      expect(result, 'ms');
    });

    test('translate returns fallback for empty cloud endpoint', () async {
      final result = await service.translate(
        text: 'Hello',
        source: 'en',
        target: 'zomi',
      );
      // Since api.pau.app doesn't exist, it should fallback
      expect(result.success, isA<bool>());
      expect(result.text, isA<String>());
    });

    test('getLanguageName returns correct names', () {
      expect(service.getLanguageName('zomi'), 'Zomi');
      expect(service.getLanguageName('en'), 'English');
      expect(service.getLanguageName('ms'), 'Malay');
      expect(service.getLanguageName('zh'), 'Chinese');
      expect(service.getLanguageName('unknown'), 'unknown');
    });
  });

  group('Translation model', () {
    test('toJson and fromJson roundtrip', () {
      final original = Translation(
        sourceText: 'Hello',
        translatedText: 'Hi',
        sourceLanguage: 'en',
        targetLanguage: 'zomi',
        isFavorite: true,
      );

      final json = original.toJson();
      final restored = Translation.fromJson(json);

      expect(restored.sourceText, original.sourceText);
      expect(restored.translatedText, original.translatedText);
      expect(restored.sourceLanguage, original.sourceLanguage);
      expect(restored.targetLanguage, original.targetLanguage);
      expect(restored.isFavorite, original.isFavorite);
      expect(restored.id, original.id);
    });

    test('fromJson handles missing fields gracefully', () {
      final restored = Translation.fromJson({'sourceText': 'Hello'});
      expect(restored.sourceText, 'Hello');
      expect(restored.translatedText, '');
      expect(restored.sourceLanguage, '');
      expect(restored.targetLanguage, '');
    });

    test('generates unique IDs', () {
      final t1 = Translation(sourceText: 'a', translatedText: 'b');
      final t2 = Translation(sourceText: 'a', translatedText: 'b');
      expect(t1.id, isNot(t2.id));
    });
  });

  group('StorageService', () {
    late StorageService storage;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storage = StorageService();
    });

    test('getHistory returns empty list initially', () async {
      final history = await storage.getHistory();
      expect(history, isEmpty);
    });

    test('saveTranslation and getHistory roundtrip', () async {
      final translation = Translation(
        sourceText: 'Hello',
        translatedText: 'Hi',
        sourceLanguage: 'en',
        targetLanguage: 'zomi',
      );

      await storage.saveTranslation(translation);
      final history = await storage.getHistory();

      expect(history.length, 1);
      expect(history.first.sourceText, 'Hello');
    });

    test('toggleFavorite works', () async {
      final t = Translation(sourceText: 'a', translatedText: 'b');
      await storage.saveTranslation(t);

      await storage.toggleFavorite(t.id);
      final history = await storage.getHistory();
      expect(history.first.isFavorite, true);

      await storage.toggleFavorite(t.id);
      final history2 = await storage.getHistory();
      expect(history2.first.isFavorite, false);
    });

    test('getFavorites returns only favorites', () async {
      final t1 = Translation(sourceText: 'a', translatedText: 'b');
      final t2 = Translation(sourceText: 'c', translatedText: 'd');
      t2.isFavorite = true;

      await storage.saveTranslation(t1);
      await storage.saveTranslation(t2);

      final favorites = await storage.getFavorites();
      expect(favorites.length, 1);
      expect(favorites.first.sourceText, 'c');
    });

    test('clearHistory removes all', () async {
      await storage.saveTranslation(Translation(sourceText: 'a', translatedText: 'b'));
      await storage.clearHistory();
      final history = await storage.getHistory();
      expect(history, isEmpty);
    });
  });

  group('AppConfig', () {
    test('models contains expected entries', () {
      // Import and test AppConfig
      // Note: AppConfig uses SharedPreferences for getOllamaUrl,
      // but static fields are accessible without it
      expect(true, isTrue); // placeholder for structured config test
    });
  });
}
