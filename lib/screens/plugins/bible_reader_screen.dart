import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/bible_loader.dart';

class BibleReaderScreen extends StatefulWidget {
  const BibleReaderScreen({super.key});

  @override
  State<BibleReaderScreen> createState() => _BibleReaderScreenState();
}

class _BibleReaderScreenState extends State<BibleReaderScreen> {
  int _translationIndex = 0;
  int _currentBook = 0;
  int _currentChapter = 1;
  final _scrollController = ScrollController();

  List<BibleTranslation> get _translations => BibleLoader.translations;
  BibleTranslation? get _active => _translationIndex < _translations.length ? _translations[_translationIndex] : null;

  @override
  void initState() {
    super.initState();
    if (_active != null) _loadProgress();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String get _currentBookName {
    final t = _active;
    if (t == null) return '';
    return t.bookNames.length > _currentBook ? t.bookNames[_currentBook] : '';
  }

  List<String> get _currentVerses {
    final t = _active;
    if (t == null) return [];
    final bounds = t.boundaries;
    if (_currentBook >= bounds.length) return [];
    final book = bounds[_currentBook];
    final chCount = _chapterCountFor(_currentBook);
    final avgPerChapter = chCount > 0 ? book.verseCount ~/ chCount : 1;
    final start = ((_currentChapter - 1) * avgPerChapter).clamp(0, book.verseCount);
    final end = _currentChapter == chCount
        ? book.verseCount
        : (_currentChapter * avgPerChapter).clamp(start + 1, book.verseCount);
    final count = (end - start).clamp(1, book.verseCount - start);
    if (count <= 0) return [];
    return t.getRange(book.startLine + start, count);
  }

  int _chapterCountFor(int bookIdx) {
    final t = _active;
    if (t == null) return 1;
    // Use standard chapter counts from metadata (approximate from verse counts)
    const std = [50,40,27,36,34,24,21,4,31,24,22,25,29,36,10,13,10,42,150,31,12,8,66,52,5,48,12,14,3,9,1,4,7,3,3,3,2,14,4,28,16,24,21,28,16,16,13,6,6,4,4,5,3,6,4,3,1,13,5,5,3,5,1,1,1,22];
    return bookIdx < std.length ? std[bookIdx] : 1;
  }

  void _openChapter(int bookIdx, int chapter) {
    final t = _active;
    if (t == null) return;
    final maxCh = _chapterCountFor(bookIdx);
    setState(() { _currentBook = bookIdx; _currentChapter = chapter.clamp(1, maxCh); });
    _saveProgress();
    _scrollController.jumpTo(0);
  }

  void _prevChapter() {
    final t = _active;
    if (t == null) return;
    final bounds = t.boundaries;
    if (_currentChapter > 1) { _openChapter(_currentBook, _currentChapter - 1); }
    else if (_currentBook > 0) { _openChapter(_currentBook - 1, _chapterCountFor(_currentBook - 1)); }
  }

  void _nextChapter() {
    final t = _active;
    if (t == null) return;
    final bounds = t.boundaries;
    if (_currentChapter < _chapterCountFor(_currentBook)) { _openChapter(_currentBook, _currentChapter + 1); }
    else if (_currentBook < bounds.length - 1) { _openChapter(_currentBook + 1, 1); }
  }

  Future<void> _loadProgress() async {
    // Placeholder — progress will use Hive when refactored
  }

  Future<void> _saveProgress() async {
    // Placeholder
  }

  void _showPicker(BuildContext context) {
    final t = _active;
    if (t == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (ctx) => _Picker(translation: t, currentBook: _currentBook, currentChapter: _currentChapter, onSelect: (b, c) { Navigator.pop(ctx); _openChapter(b, c); }),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_translations.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Loading Bibles...', style: TextStyle(color: AppTheme.textSecondaryLight)),
          ]),
        ),
      );
    }

    final t = _active!;
    final verses = _currentVerses;
    final bookName = _currentBookName;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A2E) : const Color(0xFFFDF8F0);
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF2D1B00);
    final accentColor = isDark ? AppTheme.bubbleUserDark : AppTheme.primary;
    final hasPrev = _currentChapter > 1 || _currentBook > 0;
    final hasNext = _currentChapter < _chapterCountFor(_currentBook) || _currentBook < t.boundaries.length - 1;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: GestureDetector(
          onHorizontalDragEnd: (d) {
            final v = d.primaryVelocity ?? 0;
            if (v < -80 && hasNext) _nextChapter();
            else if (v > 80 && hasPrev) _prevChapter();
          },
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
                child: Row(
                  children: [
                    IconButton(icon: Icon(Icons.arrow_back, color: accentColor.withAlpha(150), size: 20), onPressed: () => Navigator.pop(context)),
                    GestureDetector(
                      onTap: () => _showPicker(context),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text('$bookName $_currentChapter', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: accentColor)),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_drop_down, color: accentColor.withAlpha(120), size: 18),
                      ]),
                    ),
                    const Spacer(),
                    // Translation cycle
                    if (_translations.length > 1)
                      GestureDetector(
                        onTap: () {
                          setState(() => _translationIndex = (_translationIndex + 1) % _translations.length);
                          _scrollController.jumpTo(0);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: accentColor.withAlpha(25), borderRadius: BorderRadius.circular(10)),
                          child: Text(t.code.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: accentColor, letterSpacing: 0.5)),
                        ),
                      ),
                    const SizedBox(width: 6),
                    Text('$_currentChapter/${_chapterCountFor(_currentBook)}', style: TextStyle(fontSize: 11, color: accentColor.withAlpha(80))),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: verses.isEmpty
                      ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.auto_stories, size: 32, color: textColor.withAlpha(60)),
                          const SizedBox(height: 12),
                          Text('Chapter $_currentChapter', style: TextStyle(color: textColor.withAlpha(100), fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text('Not yet available', style: TextStyle(color: textColor.withAlpha(60), fontSize: 13)),
                        ]))
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.only(bottom: 40),
                          itemCount: verses.length,
                          itemBuilder: (_, i) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text.rich(TextSpan(children: [
                                WidgetSpan(alignment: PlaceholderAlignment.middle, child: Container(margin: const EdgeInsets.only(right: 4), child: Text('${i + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: accentColor.withAlpha(180))))),
                                TextSpan(text: verses[i], style: TextStyle(fontSize: 17, height: 1.8, color: textColor)),
                              ])),
                            );
                          },
                        ),
                ),
              ),
              if (verses.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('← swipe  ·  tap book name  ·  swipe →', style: TextStyle(fontSize: 10, color: textColor.withAlpha(40))),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Picker extends StatefulWidget {
  final BibleTranslation translation;
  final int currentBook;
  final int currentChapter;
  final void Function(int bookIdx, int chapter) onSelect;
  const _Picker({required this.translation, required this.currentBook, required this.currentChapter, required this.onSelect});

  @override
  State<_Picker> createState() => _PickerState();
}

class _PickerState extends State<_Picker> {
  int _selectedBook = 0;
  final _searchCtrl = TextEditingController();
  List<int> _filtered = [];

  static const _chapterCounts = [50,40,27,36,34,24,21,4,31,24,22,25,29,36,10,13,10,42,150,31,12,8,66,52,5,48,12,14,3,9,1,4,7,3,3,3,2,14,4,28,16,24,21,28,16,16,13,6,6,4,4,5,3,6,4,3,1,13,5,5,3,5,1,1,1,22];

  @override
  void initState() { super.initState(); _selectedBook = widget.currentBook; _filtered = List.generate(widget.translation.bookCount, (i) => i); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF242526) : Colors.white;
    final book = widget.translation.bookNames.length > _selectedBook ? widget.translation.bookNames[_selectedBook] : '';
    final chCount = _selectedBook < _chapterCounts.length ? _chapterCounts[_selectedBook] : 1;

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(children: [
        Container(margin: const EdgeInsets.only(top: 8), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchCtrl,
            decoration: const InputDecoration(hintText: 'Search book...', prefixIcon: Icon(Icons.search, size: 20), contentPadding: EdgeInsets.symmetric(vertical: 8)),
            onChanged: (q) {
              setState(() {
                if (q.isEmpty) {
                  _filtered = List.generate(widget.translation.bookCount, (i) => i);
                } else {
                  final query = q.toLowerCase();
                  _filtered = [];
                  for (var i = 0; i < widget.translation.bookCount; i++) {
                    if (widget.translation.bookNames[i].toLowerCase().contains(query)) _filtered.add(i);
                  }
                }
              });
            },
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Row(children: [
            SizedBox(
              width: 140,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: _filtered.length,
                itemBuilder: (_, i) {
                  final bi = _filtered[i];
                  final isActive = bi == _selectedBook;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Material(
                      color: isActive ? AppTheme.primary.withAlpha(25) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => setState(() => _selectedBook = bi),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          child: Text(widget.translation.bookNames[bi],
                            style: TextStyle(fontSize: 13, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal, color: isActive ? AppTheme.primary : null)),
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
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, childAspectRatio: 1.2, crossAxisSpacing: 4, mainAxisSpacing: 4),
                itemCount: chCount,
                itemBuilder: (_, i) {
                  final ch = i + 1;
                  final isActive = _selectedBook == widget.currentBook && ch == widget.currentChapter;
                  return Material(
                    color: isActive ? AppTheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => widget.onSelect(_selectedBook, ch),
                      child: Center(child: Text('$ch', style: TextStyle(fontSize: 14, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal, color: isActive ? Colors.white : null))),
                    ),
                  );
                },
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
