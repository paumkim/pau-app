import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/bible_loader.dart';

class BibleReaderScreen extends StatefulWidget {
  const BibleReaderScreen({super.key});

  @override
  State<BibleReaderScreen> createState() => _BibleReaderScreenState();
}

class _BibleReaderScreenState extends State<BibleReaderScreen> {
  // Books + chapters computed from the loaded Bible
  final List<_BookInfo> _books = [];
  late int _currentBook;
  late int _currentChapter;
  final _scrollController = ScrollController();
  bool _showControls = false;

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
    // Safe bounds — chapter 1 gets the first chunk, last chapter gets the remainder
    final start = ((_currentChapter - 1) * avgPerChapter).clamp(0, totalVerses);
    final end = _currentChapter == chCount
        ? totalVerses
        : (_currentChapter * avgPerChapter).clamp(start + 1, totalVerses);
    final count = (end - start).clamp(1, totalVerses - start);
    if (count <= 0) return [];
    return BibleLoader.getRange(book.startLine + start, count);
  }

  String get _currentBookName => _books[_currentBook].name;

  void _openChapter(int bookIdx, int chapter) {
    setState(() {
      _currentBook = bookIdx;
      _currentChapter = chapter.clamp(1, _books[bookIdx].chapters);
      _showControls = false;
    });
    _scrollController.jumpTo(0);
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (ctx) => _BookChapterPicker(
        books: _books,
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
    final verseNumColor = isDark ? AppTheme.bubbleUserDark : AppTheme.primary;
    final topPad = MediaQuery.of(context).viewPadding.top;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Main scrollable content
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _showControls = !_showControls),
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, topPad + 12, 20, 12),
                child: Column(
                  children: [
                    // Chapter header
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16, top: 8),
                      child: GestureDetector(
                        onTap: () => _showPicker(context),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('$bookName $_currentChapter',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: verseNumColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.arrow_drop_down,
                              color: verseNumColor.withAlpha(120), size: 22),
                          ],
                        ),
                      ),
                    ),
                    // Verse list
                    Expanded(
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
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: 32,
                                        child: Text(
                                          '${i + 1}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: verseNumColor.withAlpha(150),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          verses[i],
                                          style: TextStyle(
                                            fontSize: 17,
                                            height: 1.7,
                                            color: textColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Top bar overlay
          if (_showControls)
            Container(
              padding: EdgeInsets.fromLTRB(4, topPad + 4, 4, 0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withAlpha(180), Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context)),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showPicker(context),
                      child: Row(
                        children: [
                          Text('$bookName $_currentChapter',
                            style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                            overflow: TextOverflow.ellipsis),
                          const Icon(Icons.arrow_drop_down,
                            color: Colors.white60, size: 20),
                        ],
                      ),
                    ),
                  ),
                  Text('${verses.length} verses',
                    style: const TextStyle(color: Colors.white60, fontSize: 12)),
                  const SizedBox(width: 8),
                ],
              ),
            ),

          // Bottom bar — prev/next chapter
          if (_showControls)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 8, top: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withAlpha(200), Colors.transparent],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.chevron_left, color: Colors.white70, size: 22),
                      label: const Text('Prev',
                        style: TextStyle(color: Colors.white70, fontSize: 14)),
                      onPressed: _currentChapter > 1
                          ? () => _openChapter(_currentBook, _currentChapter - 1)
                          : _currentBook > 0
                              ? () => _openChapter(_currentBook - 1, _books[_currentBook - 1].chapters)
                              : null,
                    ),
                    Text('$_currentChapter / ${_books[_currentBook].chapters}',
                      style: const TextStyle(color: Colors.white54, fontSize: 13)),
                    TextButton.icon(
                      icon: const Icon(Icons.chevron_right, color: Colors.white70, size: 22),
                      label: const Text('Next',
                        style: TextStyle(color: Colors.white70, fontSize: 14)),
                      onPressed: _currentChapter < _books[_currentBook].chapters
                          ? () => _openChapter(_currentBook, _currentChapter + 1)
                          : _currentBook < _books.length - 1
                              ? () => _openChapter(_currentBook + 1, 1)
                              : null,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Bottom sheet: book list on left, chapter grid on right.
class _BookChapterPicker extends StatefulWidget {
  final List<_BookInfo> books;
  final int currentBook;
  final int currentChapter;
  final void Function(int bookIdx, int chapter) onSelect;

  const _BookChapterPicker({
    required this.books,
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
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          // Search field
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
                // Book list
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
                              child: Text(b.name,
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
                // Chapter grid
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
