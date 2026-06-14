import 'package:flutter/services.dart';

/// Loads the full Tedim Bible (30,715 verses) from asset at runtime.
/// Shared between Bible reader and daily verse.
class BibleLoader {
  static List<String>? _verses;

  static bool get isLoaded => _verses != null;
  static int get totalVerses => _verses?.length ?? 0;
  static List<String> get allVerses => _verses ?? [];

  static Future<void> load() async {
    if (_verses != null) return;
    final raw = await rootBundle.loadString('assets/bible/tedim_verses.txt');
    _verses = raw.split('\n').where((l) => l.trim().isNotEmpty).toList();
  }

  /// Get verses for a specific line range.
  static List<String> getRange(int start, int count) {
    if (_verses == null) return [];
    final end = (start + count).clamp(0, _verses!.length);
    return _verses!.sublist(start, end);
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

  /// Verse count per book (KJV/Tedim standard).
  static const _verseCounts = [
    1533, 1213, 859, 1288, 959,  // Pentateuch
    658, 618, 85, 810, 706,      // History
    816, 719, 942, 822, 280,     // History cont.
    279, 167, 1070, 2461, 915,   // Wisdom
    222, 117, 3472, 3055, 154,   // Major prophets
    1273, 357, 197, 73, 146,     // Minor prophets
    21, 48, 105, 47, 56,         // Minor cont.
    53, 38, 211, 67,             // Post-exile
    1071, 678, 1151, 879, 1007,  // Gospels + Acts
    433, 437, 257, 149, 155,     // Paul's letters
    104, 95, 89, 47,             // Paul cont.
    113, 83, 46, 25,             // Pastoral
    303, 108, 105, 61, 79,       // General
    23, 13, 25, 404,             // Revelation
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
