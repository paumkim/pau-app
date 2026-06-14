/// Full-text Bible search engine.
/// Searches by book name, verse text, or partial passage.
/// The search index is structured so content can grow without changing the engine.
class BibleSearch {
  const BibleSearch._();

  static final List<_BibleVerse> _verses = [
    // Genesis 1
    _BibleVerse('Piancilna', 1, 1, 'A kilaina in Pasian in van leh lei a piangsak hi.'),
    _BibleVerse('Piancilna', 1, 2, 'Lei in gamla leh lau-a om a, thim in tuikhuklak tungah khem a; Pasian\' Tha in tui tungah omkhip hi.'),
    _BibleVerse('Piancilna', 1, 3, 'Pasian in, "Khuamuang om henla," a ci a, khuamuang om ta hi.'),
    _BibleVerse('Piancilna', 1, 4, 'Pasian in khuamuang a hoihlam mu a, khuamuang leh thim a khen hi.'),
    _BibleVerse('Piancilna', 1, 5, 'Pasian in khuamuang "Ni" a ci a, thim "Zan" a ci hi.'),
    _BibleVerse('Piancilna', 1, 6, 'Pasian in, "Tui lai ah van khatpen om henla, tui leh tui a khen hen," a ci hi.'),
    _BibleVerse('Piancilna', 1, 7, 'Pasian in vanpi khatpen a bawl a, vanpi nuai a tuite leh vanpi tung a tuite a khen hi.'),
    _BibleVerse('Piancilna', 1, 8, 'Pasian in vanpi "Van" a ci hi.'),
    _BibleVerse('Piancilna', 1, 9, 'Pasian in, "Van nuai a tuite khatpeuhin om unla, a kang gamte kilang hen," a ci hi.'),
    _BibleVerse('Piancilna', 1, 10, 'Pasian in a kang gam "Lei" a ci a, tuikhawlte "Tuikhuk" a ci hi.'),
    _BibleVerse('Piancilna', 1, 11, 'Pasian in, "Lei in note\'a kung piang hen," a ci hi.'),
    _BibleVerse('Piancilna', 1, 12, 'Lei in note\'a kung a piang hi.'),
    _BibleVerse('Piancilna', 1, 13, 'Noptui leh zingsang a kimkhatin ni thumna hi.'),
    _BibleVerse('Piancilna', 1, 14, 'Pasian in, "Van piangun khuavak om henla, ni leh zan a khen hen," a ci hi.'),
    _BibleVerse('Piancilna', 1, 15, 'Pasian in vantungah a khuavakpi nih a bawl hi.'),
    _BibleVerse('Piancilna', 1, 16, 'Pasian in vantungah a khuavakpi lian nih a bawl a, khuavak lianpen ni uk nading hi.'),
    _BibleVerse('Piancilna', 1, 17, 'Pasian in leitung tungah khuamuang pia nading vantungah a koih hi.'),
    _BibleVerse('Piancilna', 1, 18, 'Ni leh zan ukna, khuamuang leh thim khenna ding a bawl hi.'),
    _BibleVerse('Piancilna', 1, 19, 'Noptui leh zingsang a kimkhatin ni lina hi.'),
    _BibleVerse('Piancilna', 1, 20, 'Pasian in, "Tui in a nungta ahingte tamtakin suak henla," a ci hi.'),
    _BibleVerse('Piancilna', 1, 21, 'Pasian in tuipi a tualte, note\'a vate a piangsak hi.'),
    _BibleVerse('Piancilna', 1, 22, 'Pasian in, "Na tam unla, leitung khempeuh ah king unla," a ci hi.'),
    _BibleVerse('Piancilna', 1, 23, 'Noptui leh zingsang a kimkhatin ni gana hi.'),
    _BibleVerse('Piancilna', 1, 24, 'Pasian in, "Lei in a nungta ahingte suak hen," a ci hi.'),
    _BibleVerse('Piancilna', 1, 25, 'Pasian in gam namkimte a piangsak hi.'),
    _BibleVerse('Piancilna', 1, 26, 'Pasian in, "Eite lim leh eimah bangin mihing bawl ni," a ci hi.'),
    _BibleVerse('Piancilna', 1, 27, 'Pasian in mihing a lim mah bangin a piangsak a, pasal leh numei a piangsak hi.'),
    _BibleVerse('Piancilna', 1, 28, 'Pasian in, "Na tam unla, leitung khempeuh king unla, uk unla," a ci hi.'),
    _BibleVerse('Piancilna', 1, 29, 'Pasian in, "Note\' ading a ngetna ding uh ahi hi," a ci hi.'),
    _BibleVerse('Piancilna', 1, 30, 'Tu a nungta khempeuh a dingin ka pia hi, a ci hi.'),
    _BibleVerse('Piancilna', 1, 31, 'Pasian in a bawl khempeuh a hoih lua mu hi. Noptui leh zingsang a kimkhatin ni gukna hi.'),
  ];

  static const _bookNameIndex = {
    'piancilna': 'Piancilna', 'genesis': 'Piancilna', 'gen': 'Piancilna',
    'paikhiatna': 'Paikhiatna', 'exodus': 'Paikhiatna', 'exo': 'Paikhiatna',
    'siampi': 'Siampi Laibu', 'leviticus': 'Siampi Laibu', 'lev': 'Siampi Laibu',
    'gamlak': 'Gamlak Vakna', 'numbers': 'Gamlak Vakna', 'num': 'Gamlak Vakna',
    'thu hilhkikna': 'Thu Hilhkikna', 'deuteronomy': 'Thu Hilhkikna', 'deu': 'Thu Hilhkikna',
    'joshua': 'Joshua', 'josh': 'Joshua',
    'thukhente': 'Thukhente', 'judges': 'Thukhente', 'judg': 'Thukhente',
    'ruth': 'Ruth',
    'samuel': 'Samuel',
    'siangte': 'Siangte', 'kings': 'Siangte',
    'chronicles': 'Chronicles',
    'ezra': 'Ezra', 'nehemiah': 'Nehemiah',
    'esther': 'Esther',
    'job': 'Job',
    'late': 'Late', 'psalms': 'Late', 'psalm': 'Late',
    'paukhakna': 'Paukhakna', 'proverbs': 'Paukhakna', 'prov': 'Paukhakna',
    'vaipuak': 'Vaipuak', 'ecclesiastes': 'Vaipuak',
    'late sia': 'Late Sia', 'song of solomon': 'Late Sia',
    'isaiah': 'Isaiah', 'isa': 'Isaiah',
    'jeremiah': 'Jeremiah', 'jer': 'Jeremiah',
    'lamentations': 'Lamentations',
    'ezekiel': 'Ezekiel', 'ezek': 'Ezekiel',
    'daniel': 'Daniel', 'dan': 'Daniel',
    'hosea': 'Hosea',
    'joel': 'Joel',
    'amos': 'Amos',
    'obadiah': 'Obadiah',
    'jonah': 'Jonah',
    'micah': 'Micah',
    'nahum': 'Nahum',
    'habakkuk': 'Habakkuk',
    'zephaniah': 'Zephaniah',
    'haggai': 'Haggai',
    'zechariah': 'Zechariah',
    'malachi': 'Malachi',
    'matthew': 'Matthew', 'matt': 'Matthew',
    'mark': 'Mark',
    'luke': 'Luke',
    'john': 'John',
    'acts': 'Thukhente',
    'rome': 'Rome', 'romans': 'Rome',
    'corinthians': 'Corinthians',
    'galatia': 'Galatia', 'galatians': 'Galatia',
    'ephesus': 'Ephesus', 'ephesians': 'Ephesus',
    'philippi': 'Philippi', 'philippians': 'Philippi',
    'colossae': 'Colossae', 'colossians': 'Colossae',
    'thessalon': 'Thessalonica',
    'timothy': 'Timothy',
    'titus': 'Titus',
    'philemon': 'Philemon',
    'hebrew': 'Hebrew', 'hebrews': 'Hebrew',
    'james': 'James',
    'peter': 'Peter',
    'jude': 'Jude',
    'mangmuhna': 'Mangmuhna', 'revelation': 'Mangmuhna', 'rev': 'Mangmuhna',
  };

  /// All available verses (used by daily verse).
  static List<BibleSearchResult> get allVerses {
    return _verses.map((v) => BibleSearchResult(
      book: v.book, chapter: v.chapter, verse: v.verse,
      text: v.text, matchType: 'all',
    )).toList();
  }

  /// Search across all available Bible content.
  /// Returns verses where the book name, chapter, or text matches.
  static List<BibleSearchResult> search(String query) {
    if (query.trim().isEmpty) return [];
    final q = query.toLowerCase().trim();
    final results = <BibleSearchResult>[];

    // Try to match a book name first
    String? targetBook;
    int? targetChapter;
    final parts = q.split(RegExp(r'\s+'));

    // Check if first word(s) match a book
    for (var i = parts.length; i > 0; i--) {
      final bookGuess = parts.take(i).join(' ');
      if (_bookNameIndex.containsKey(bookGuess)) {
        targetBook = _bookNameIndex[bookGuess];
        // Check if remaining words include a chapter number
        if (i < parts.length) {
          final chNum = int.tryParse(parts[i]);
          if (chNum != null) targetChapter = chNum;
        }
        break;
      }
    }

    // Search by book + chapter
    if (targetBook != null) {
      for (final v in _verses) {
        if (v.book == targetBook) {
          if (targetChapter == null || v.chapter == targetChapter) {
            results.add(BibleSearchResult(
              book: v.book, chapter: v.chapter, verse: v.verse,
              text: v.text, matchType: 'book',
            ));
          }
        }
      }
      if (results.isNotEmpty) return results.take(20).toList();
    }

    // Full-text search across all verses
    for (final v in _verses) {
      if (v.text.toLowerCase().contains(q) ||
          v.book.toLowerCase().contains(q)) {
        results.add(BibleSearchResult(
          book: v.book, chapter: v.chapter, verse: v.verse,
          text: v.text, matchType: 'text',
        ));
      }
      if (results.length >= 20) break;
    }

    return results;
  }
}

class _BibleVerse {
  final String book;
  final int chapter;
  final int verse;
  final String text;
  const _BibleVerse(this.book, this.chapter, this.verse, this.text);
}

class BibleSearchResult {
  final String book;
  final int chapter;
  final int verse;
  final String text;
  final String matchType;
  const BibleSearchResult({
    required this.book,
    required this.chapter,
    required this.verse,
    required this.text,
    required this.matchType,
  });

  String get reference => '$book $chapter:$verse';
}
