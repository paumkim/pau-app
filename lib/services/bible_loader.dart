import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum BibleLanguage { tedim, english }

/// Loads the full Tedim Bible (30,715 verses) + English KJV from assets.
/// Shared between Bible reader and daily verse.
class BibleLoader {
  static List<String>? _verses;
  static List<String>? _enVerses;

  static bool get isLoaded => _verses != null;
  static int get totalVerses => _verses?.length ?? 0;
  static List<String> get allVerses => _verses ?? [];
  static List<String> get enVerses => _enVerses ?? [];

  static Future<void> load() async {
    if (_verses != null) return;
    // Tedim
    final raw = await rootBundle.loadString('assets/bible/tedim_verses.txt');
    _verses = raw.split('\n').where((l) => l.trim().isNotEmpty).toList();
    // English KJV
    try {
      final enRaw = await rootBundle.loadString('assets/bible/eng_kjv.txt');
      _enVerses = enRaw.split('\n').where((l) => l.trim().isNotEmpty).toList();
    } catch (e) {
      _enVerses = [];
    }
  }

  /// Get verses for a specific line range in the active language.
  static List<String> getRange(int start, int count, {BibleLanguage lang = BibleLanguage.tedim}) {
    final verses = lang == BibleLanguage.english ? _enVerses : _verses;
    if (verses == null) return [];
    final end = (start + count).clamp(0, verses.length);
    return verses.sublist(start, end);
  }

  /// All verses in a specific language.
  static List<String> allFor(BibleLanguage lang) {
    return lang == BibleLanguage.english ? enVerses : allVerses;
  }

  /// Book boundaries: [bookIndex] = start line.
  /// Computed from standard Tedim Bible verse counts.
  static const bookNames = [
    'Piancilna', 'Paikhiatna', 'Siampi Laibu', 'Gamlak Vakna', 'Thu Hilhkikna',
    'Joshua', 'Thukhente', 'Ruth', '1 Samuel', '2 Samuel',
    '1 Siangte', '2 Siangte', '1 Chronicles', '2 Chronicles', 'Ezra',
    'Nehemiah', 'Esther', 'Job', 'Late', 'Paukhakna',
    'Vaipuak', 'Late Sia', 'Isaiah', 'Jeremiah', 'Lamentations',
    'Ezekiel', 'Daniel', 'Hosea', 'Joel', 'Amos',
    'Obadiah', 'Jonah', 'Micah', 'Nahum', 'Habakkuk',
    'Zephaniah', 'Haggai', 'Zechariah', 'Malachi',
    'Matthew', 'Mark', 'Luke', 'John', 'Thukhente',
    'Rome', '1 Corinthians', '2 Corinthians', 'Galatia', 'Ephesus',
    'Philippi', 'Colossae', '1 Thessalonica', '2 Thessalonica',
    '1 Timothy', '2 Timothy', 'Titus', 'Philemon',
    'Hebrew', 'James', '1 Peter', '2 Peter', '1 John', '2 John', '3 John', 'Jude',
    'Mangmuhna',
  ];

  /// Verse count per book (KJV standard — used by both Tedim and English).
  /// KJV sums to 31100. Tedim has 30715 (some verses combined).
  /// We use KJV counts for navigation; actual text display is file-length-safe.
  static const _verseCounts = [
    1533, 1213, 859, 1288, 959,
    658, 618, 85, 811, 695,
    817, 719, 942, 822, 280,
    406, 167, 1070, 2461, 915,
    222, 117, 1292, 1364, 154,
    1273, 357, 197, 73, 146,
    21, 48, 105, 47, 56,
    53, 38, 211, 55,
    1068, 675, 1151, 879, 1007,
    433, 437, 257, 149, 155,
    104, 95, 89, 47,
    113, 83, 46, 25,
    303, 108, 105, 61, 105,
    13, 15, 25, 405,
  ];

  static List<_BookBoundary> get boundaries {
    var start = 0;
    final result = <_BookBoundary>[];
    for (var i = 0; i < bookNames.length; i++) {
      result.add(_BookBoundary(bookNames[i], start, _verseCounts[i]));
      start += _verseCounts[i];
    }
    return result;
  }

  /// Search by ANY text across the entire Bible.
  static List<_SearchMatch> search(String query) {
    if (_verses == null || query.trim().isEmpty) return [];
    final q = query.toLowerCase();
    final results = <_SearchMatch>[];

    final bounds = boundaries;
    var globalLine = 0;
    for (var bookIdx = 0; bookIdx < bounds.length; bookIdx++) {
      final book = bounds[bookIdx];
      for (var line = 0; line < book.verseCount; line++) {
        globalLine = book.startLine + line;
        if (globalLine >= _verses!.length) break;

        final text = _verses![globalLine];
        if (text.toLowerCase().contains(q)) {
          results.add(_SearchMatch(book.name, line, text));
          if (results.length >= 30) return results;
        }
      }
    }
    return results;
  }
}

class _BookBoundary {
  final String name;
  final int startLine;
  final int verseCount;
  const _BookBoundary(this.name, this.startLine, this.verseCount);
}

class _SearchMatch {
  final String book;
  final int verseIndex; // 0-based within book
  final String text;
  const _SearchMatch(this.book, this.verseIndex, this.text);
  int get verseNumber => verseIndex + 1;
}
