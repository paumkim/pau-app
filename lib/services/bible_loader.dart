import 'dart:convert';
import 'package:flutter/services.dart';

/// Loads Bible translations from assets/bibles/<code>/.
/// Each translation has:
///   - verses.txt  (one verse per line)
///   - metadata.json (name, language, book names, verse counts)
///
/// Adding a new Bible: drop a folder in assets/bibles/ with those files.
class BibleLoader {
  static final List<BibleTranslation> _translations = [];
  static bool _loaded = false;

  static List<BibleTranslation> get translations => List.unmodifiable(_translations);
  static bool get isLoaded => _loaded;

  static Future<void> loadAll() async {
    if (_loaded) return;
    try {
      final manifest = await rootBundle.loadString('AssetManifest.json');
      final paths = jsonDecode(manifest).keys;

      // Find all metadata.json files under assets/bibles/
      for (final path in paths) {
        if (path.startsWith('assets/bibles/') && path.endsWith('/metadata.json')) {
          try {
            final meta = jsonDecode(await rootBundle.loadString(path));
            final dir = path.replaceAll('/metadata.json', '');
            final verses = await rootBundle.loadString('$dir/verses.txt');
            final lines = verses.split('\n').where((l) => l.trim().isNotEmpty).toList();

            _translations.add(BibleTranslation(
              code: meta['code'] ?? dir.split('/').last,
              name: meta['name'] ?? 'Unknown',
              language: meta['language'] ?? '',
              direction: meta['direction'] ?? 'ltr',
              bookNames: List<String>.from(meta['bookNames'] ?? []),
              enNames: List<String>.from(meta['enNames'] ?? []),
              verseCounts: List<int>.from(meta['verseCounts'] ?? []),
              verses: lines,
            ));
          } catch (e) {
            // Skip invalid translation
          }
        }
      }
      _loaded = true;
    } catch (e) {
      _loaded = true;
    }
  }

  /// Get a translation by code. Returns null if not found.
  static BibleTranslation? get(String code) {
    try {
      return _translations.firstWhere((t) => t.code == code);
    } catch (_) {
      return null;
    }
  }
}

class BibleTranslation {
  final String code;
  final String name;
  final String language;
  final String direction;
  final List<String> bookNames;
  final List<String> enNames;
  final List<int> verseCounts;
  final List<String> verses;

  const BibleTranslation({
    required this.code,
    required this.name,
    required this.language,
    required this.direction,
    required this.bookNames,
    required this.enNames,
    required this.verseCounts,
    required this.verses,
  });

  int get totalVerses => verses.length;
  int get bookCount => bookNames.length;

  /// Get verses for a specific line range.
  List<String> getRange(int start, int count) {
    final end = (start + count).clamp(0, verses.length);
    return verses.sublist(start, end);
  }

  /// Compute [startLine, verseCount] for each book.
  List<_BookBoundary> get boundaries {
    var start = 0;
    final result = <_BookBoundary>[];
    for (var i = 0; i < bookNames.length; i++) {
      final vc = i < verseCounts.length ? verseCounts[i] : 1;
      result.add(_BookBoundary(bookNames[i], start, vc));
      start += vc;
    }
    return result;
  }
}

class _BookBoundary {
  final String name;
  final int startLine;
  final int verseCount;
  const _BookBoundary(this.name, this.startLine, this.verseCount);
}
