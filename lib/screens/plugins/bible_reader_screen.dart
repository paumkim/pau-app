import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/bible_loader.dart' show BibleLoader, BibleLanguage;

class BibleReaderScreen extends StatefulWidget {
  const BibleReaderScreen({super.key});

  @override
  State<BibleReaderScreen> createState() => _BibleReaderScreenState();
}

class _BibleReaderScreenState extends State<BibleReaderScreen> {
  final List<_BookInfo> _books = [];
  late int _currentBook;
  late int _currentChapter;
  final _scrollController = ScrollController();
  BibleLanguage _language = BibleLanguage.tedim;

  static final List<int> _chapterCounts = [
    50, 40, 27, 36, 34, 24, 21, 4, 31, 24,
    22, 25, 29, 36, 10, 13, 10, 42, 150, 31,
    12, 8, 66, 52, 5, 48, 12, 14, 3, 9,
    1, 4, 7, 3, 3, 3, 2, 14, 4,
    28, 16, 24, 21, 28, 16, 16, 13, 6, 6,
    4, 4, 5, 3, 6, 4, 3, 1,
    13, 5, 5, 3, 5, 1, 1, 1, 22,
  ];

  @override
  void initState() {
    super.initState();
    final bounds = BibleLoader.boundaries;
    for (var i = 0; i < bounds.length; i++) {
      _books.add(_BookInfo(
        name: bounds[i].name,
        startLine: bounds[i].startLine,
        verseCount: bounds[i].verseCount,
        chapters: i < _chapterCounts.length ? _chapterCounts[i] : 1,
      ));
    }
    _currentBook = 0;
    _currentChapter = 1;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<String> get _currentVerses {
    final book = _books[_currentBook];
    final chCount = book.chapters;
    final totalVerses = book.verseCount;
    final avgPerChapter = totalVerses ~/ chCount;
    final start = ((_currentChapter - 1) * avgPerChapter).clamp(0, totalVerses);
    final end = _currentChapter == chCount
        ? totalVerses
        : (_currentChapter * avgPerChapter).clamp(start + 1, totalVerses);
    final count = (end - start).clamp(1, totalVerses - start);
    if (count <= 0) return [];
    return BibleLoader.getRange(book.startLine + start, count, lang: _language);
  }

  String get _currentBookName {
    final tedim = _books[_currentBook].name;
    if (_language == BibleLanguage.english) {
      return _enBookNames[_currentBook];
    }
    return tedim;
  }

  static const _enBookNames = [
    'Genesis', 'Exodus', 'Leviticus', 'Numbers', 'Deuteronomy',
    'Joshua', 'Judges', 'Ruth', '1 Samuel', '2 Samuel',
    '1 Kings', '2 Kings', '1 Chronicles', '2 Chronicles', 'Ezra',
    'Nehemiah', 'Esther', 'Job', 'Psalms', 'Proverbs',
    'Ecclesiastes', 'Song of Solomon', 'Isaiah', 'Jeremiah', 'Lamentations',
    'Ezekiel', 'Daniel', 'Hosea', 'Joel', 'Amos',
    'Obadiah', 'Jonah', 'Micah', 'Nahum', 'Habakkuk',
    'Zephaniah', 'Haggai', 'Zechariah', 'Malachi',
    'Matthew', 'Mark', 'Luke', 'John', 'Acts',
    'Romans', '1 Corinthians', '2 Corinthians', 'Galatians', 'Ephesians',
    'Philippians', 'Colossians', '1 Thessalonians', '2 Thessalonians',
    '1 Timothy', '2 Timothy', 'Titus', 'Philemon',
    'Hebrews', 'James', '1 Peter', '2 Peter', '1 John', '2 John', '3 John', 'Jude',
    'Revelation',
  ];

  void _openChapter(int bookIdx, int chapter) {
    setState(() {
      _currentBook = bookIdx;
      _currentChapter = chapter.clamp(1, _books[bookIdx].chapters);
    });
    _scrollController.jumpTo(0);
  }

  void _prevChapter() {
    if (_currentChapter > 1) {
      _openChapter(_currentBook, _currentChapter - 1);
    } else if (_currentBook > 0) {
      _openChapter(_currentBook - 1, _books[_currentBook - 1].chapters);
    }
  }

  void _nextChapter() {
    if (_currentChapter < _books[_currentBook].chapters) {
      _openChapter(_currentBook, _currentChapter + 1);
    } else if (_currentBook < _books.length - 1) {
      _openChapter(_currentBook + 1, 1);
    }
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (ctx) => _BookChapterPicker(
        books: _books,
        enBookNames: _enBookNames,
        language: _language,
        currentBook: _currentBook,
        currentChapter: _currentChapter,
        onSelect: (bookIdx, chapter) {
          Navigator.pop(ctx);
          _openChapter(bookIdx, chapter);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_books.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Loading Bible...',
                style: TextStyle(color: AppTheme.textSecondaryLight)),
            ],
          ),
        ),
      );
    }

    final verses = _currentVerses;
    final bookName = _currentBookName;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A2E) : const Color(0xFFFDF8F0);
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF2D1B00);
    final accentColor = isDark ? AppTheme.bubbleUserDark : AppTheme.primary;
    final hasPrev = _currentChapter > 1 || _currentBook > 0;
    final hasNext = _currentChapter < _books[_currentBook].chapters || _currentBook < _books.length - 1;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: GestureDetector(
          onHorizontalDragEnd: (d) {
            if (d.primaryVelocity! < -80 && hasNext) {
              _nextChapter();
            } else if (d.primaryVelocity! > 80 && hasPrev) {
              _prevChapter();
            }
          },
          child: Column(
            children: [
              // Header — back, chapter title, position
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back,
                        color: accentColor.withAlpha(150), size: 20),
                      onPressed: () => Navigator.pop(context)),
                    GestureDetector(
                      onTap: () => _showPicker(context),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('$bookName $_currentChapter',
                            style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w600,
                              color: accentColor)),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_drop_down,
                            color: accentColor.withAlpha(120), size: 18),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Language toggle
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _language = _language == BibleLanguage.tedim
                              ? BibleLanguage.english
                              : BibleLanguage.tedim;
                        });
                        _scrollController.jumpTo(0);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: accentColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _language == BibleLanguage.tedim ? 'TED' : 'ENG',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('${_currentChapter}/${_books[_currentBook].chapters}',
                      style: TextStyle(
                        fontSize: 11, color: accentColor.withAlpha(80))),
                    const SizedBox(width: 6),
                  ],
                ),
              ),

              // Verse list
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: verses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_stories,
                              size: 32, color: textColor.withAlpha(60)),
                            const SizedBox(height: 12),
                            Text('Chapter $_currentChapter',
                              style: TextStyle(
                                color: textColor.withAlpha(100),
                                fontSize: 16, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text('Not yet available',
                              style: TextStyle(
                                color: textColor.withAlpha(60), fontSize: 13)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(bottom: 40),
                        itemCount: verses.length,
                        itemBuilder: (_, i) {
                          final verseNum = i + 1;
                          final isChapterStart = verseNum == 1;
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: 6,
                              top: isChapterStart ? 0 : 0,
                            ),
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  WidgetSpan(
                                    alignment: PlaceholderAlignment.middle,
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 4),
                                      child: Text(
                                        '$verseNum',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: accentColor.withAlpha(180),
                                        ),
                                      ),
                                    ),
                                  ),
                                  TextSpan(
                                    text: verses[i],
                                    style: TextStyle(
                                      fontSize: 17,
                                      height: 1.8,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              ),

              // Bottom hint
              if (verses.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('← swipe  ·  tap book name to pick  ·  swipe →',
                    style: TextStyle(fontSize: 10, color: textColor.withAlpha(40))),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookChapterPicker extends StatefulWidget {
  final List<_BookInfo> books;
  final List<String> enBookNames;
  final BibleLanguage language;
  final int currentBook;
  final int currentChapter;
  final void Function(int bookIdx, int chapter) onSelect;

  const _BookChapterPicker({
    required this.books,
    required this.enBookNames,
    required this.language,
    required this.currentBook,
    required this.currentChapter,
    required this.onSelect,
  });

  @override
  State<_BookChapterPicker> createState() => _BookChapterPickerState();
}

class _BookChapterPickerState extends State<_BookChapterPicker> {
  int _selectedBook = 0;
  final _searchCtrl = TextEditingController();
  List<int> _filteredBooks = [];

  @override
  void initState() {
    super.initState();
    _selectedBook = widget.currentBook;
    _filteredBooks = List.generate(widget.books.length, (i) => i);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF242526) : Colors.white;
    final book = widget.books[_selectedBook];

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search book...',
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (q) {
                setState(() {
                  if (q.isEmpty) {
                    _filteredBooks = List.generate(widget.books.length, (i) => i);
                  } else {
                    final query = q.toLowerCase();
                    _filteredBooks = [];
                    for (var i = 0; i < widget.books.length; i++) {
                      if (widget.books[i].name.toLowerCase().contains(query)) {
                        _filteredBooks.add(i);
                      }
                    }
                  }
                });
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: 140,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: _filteredBooks.length,
                    itemBuilder: (_, i) {
                      final bookIdx = _filteredBooks[i];
                      final b = widget.books[bookIdx];
                      final isActive = bookIdx == _selectedBook;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Material(
                          color: isActive
                              ? AppTheme.primary.withAlpha(25)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => setState(() => _selectedBook = bookIdx),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                              child: Text(
                                widget.language == BibleLanguage.english && bookIdx < widget.enBookNames.length
                                    ? widget.enBookNames[bookIdx]
                                    : b.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                                  color: isActive ? AppTheme.primary : null,
                                )),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      childAspectRatio: 1.2,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                    ),
                    itemCount: book.chapters,
                    itemBuilder: (_, i) {
                      final ch = i + 1;
                      final isActive = _selectedBook == widget.currentBook && ch == widget.currentChapter;
                      return Material(
                        color: isActive ? AppTheme.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => widget.onSelect(_selectedBook, ch),
                          child: Center(
                            child: Text('$ch',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                                color: isActive ? Colors.white : null,
                              )),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BookInfo {
  final String name;
  final int startLine;
  final int verseCount;
  final int chapters;
  const _BookInfo({
    required this.name,
    required this.startLine,
    required this.verseCount,
    required this.chapters,
  });
}
