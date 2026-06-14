import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/book_content.dart';
import '../../services/hive_storage.dart';

class ReaderScreen extends StatefulWidget {
  final BookContent book;
  const ReaderScreen({super.key, required this.book});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  int _currentSection = 0;
  int _currentChapter = 0;
  bool _showControls = true;
  bool _searchMode = false;
  bool _showToc = false;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _searchQuery = '';
  List<_SearchResult> _searchResults = [];

  // Reading settings
  double _fontSize = 18.0;
  double _lineHeight = 1.8;
  bool _sepiaMode = true;

  List<Map<String, dynamic>> _bookmarks = [];

  BookSection get _section => widget.book.sections[_currentSection];
  BookChapter get _chapter => _section.chapters[_currentChapter];

  @override
  void initState() {
    super.initState();
    _loadProgress();
    _loadBookmarks();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    final progress = await HiveStorage.getProgress(widget.book.id);
    if (progress != null && mounted) {
      setState(() {
        _currentSection = progress['section'] ?? 0;
        _currentChapter = progress['chapter'] ?? 0;
      });
    }
  }

  Future<void> _loadBookmarks() async {
    final bookmarks = await HiveStorage.getBookmarks(widget.book.id);
    if (mounted) setState(() => _bookmarks = bookmarks);
  }

  Future<void> _saveProgress() async {
    await HiveStorage.saveProgress(widget.book.id, _currentSection, _currentChapter);
  }

  Future<void> _toggleBookmark() async {
    final currentKey = '${widget.book.id}_$_currentSection$_currentChapter';
    final existing = _bookmarks.where((b) =>
      b['section'] == _currentSection && b['chapter'] == _currentChapter).toList();

    if (existing.isNotEmpty) {
      await HiveStorage.removeBookmark(currentKey);
      _loadBookmarks();
      if (mounted) _showSnack('Bookmark removed');
    } else {
      await HiveStorage.saveBookmark(widget.book.id, {
        'bookId': widget.book.id,
        'bookTitle': widget.book.title,
        'section': _currentSection,
        'chapter': _currentChapter,
        'sectionTitle': _section.title,
        'chapterNumber': _chapter.number,
        'text': _getContent().substring(0, _getContent().length.clamp(0, 80)),
        'addedAt': DateTime.now().toIso8601String(),
      });
      _loadBookmarks();
      if (mounted) _showSnack('Bookmark added');
    }
  }

  bool get _isBookmarked => _bookmarks.any((b) =>
    b['section'] == _currentSection && b['chapter'] == _currentChapter);

  String _getContent() => _chapter.content.isNotEmpty
      ? _chapter.content
      : '';

  bool get _hasPrev => _currentChapter > 0 || _currentSection > 0;
  bool get _hasNext => _currentChapter < _section.chapters.length - 1
      || _currentSection < widget.book.sections.length - 1;

  void _goPrev() {
    if (_currentChapter > 0) {
      setState(() => _currentChapter--);
    } else if (_currentSection > 0) {
      setState(() {
        _currentSection--;
        _currentChapter = widget.book.sections[_currentSection].chapters.length - 1;
      });
    }
    _saveProgress();
    _scrollController.jumpTo(0);
  }

  void _goNext() {
    if (_currentChapter < _section.chapters.length - 1) {
      setState(() => _currentChapter++);
    } else if (_currentSection < widget.book.sections.length - 1) {
      setState(() { _currentSection++; _currentChapter = 0; });
    }
    _saveProgress();
    _scrollController.jumpTo(0);
  }

  void _goTo(int section, int chapter) {
    setState(() {
      _currentSection = section;
      _currentChapter = chapter;
      _showToc = false;
    });
    _saveProgress();
    _scrollController.jumpTo(0);
  }

  void _doSearch(String query) {
    if (query.length < 2) {
      setState(() { _searchQuery = ''; _searchResults = []; });
      return;
    }
    final q = query.toLowerCase();
    final results = <_SearchResult>[];
    for (var si = 0; si < widget.book.sections.length; si++) {
      for (var ci = 0; ci < widget.book.sections[si].chapters.length; ci++) {
        final content = widget.book.sections[si].chapters[ci].content;
        if (content.toLowerCase().contains(q)) {
          for (var line in content.split('\n')) {
            if (line.toLowerCase().contains(q)) {
              results.add(_SearchResult(
                section: si, chapter: ci,
                text: line.trim().length > 100
                    ? line.trim().substring(0, 100) + '...'
                    : line.trim(),
              ));
              if (results.length >= 30) break;
            }
          }
        }
        if (results.length >= 30) break;
      }
      if (results.length >= 30) break;
    }
    setState(() { _searchQuery = query; _searchResults = results; });
  }

  void _goToResult(_SearchResult r) {
    setState(() {
      _currentSection = r.section;
      _currentChapter = r.chapter;
      _searchMode = false;
      _searchQuery = '';
      _searchController.clear();
      _searchResults = [];
    });
    _saveProgress();
    _scrollController.jumpTo(0);
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 1)));
  }

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reading Settings',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Text('Font Size'),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.text_fields, size: 16),
                      onPressed: _fontSize > 14
                          ? () => setState(() => _fontSize -= 2)
                          : null,
                    ),
                    Text('${_fontSize.round()}'),
                    IconButton(
                      icon: const Icon(Icons.text_fields, size: 24),
                      onPressed: _fontSize < 28
                          ? () => setState(() => _fontSize += 2)
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Line Spacing'),
                    const Spacer(),
                    Slider(
                      value: _lineHeight,
                      min: 1.2,
                      max: 3.0,
                      divisions: 9,
                      label: _lineHeight.toStringAsFixed(1),
                      onChanged: (v) => setState(() => _lineHeight = v),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Sepia Mode'),
                    const Spacer(),
                    Switch(
                      value: _sepiaMode,
                      onChanged: (v) => setState(() => _sepiaMode = v),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = _getContent();
    final title = '${_section.title} ${_chapter.number}';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bgColor;
    Color textColor;
    if (_sepiaMode && !isDark) {
      bgColor = const Color(0xFFFDF8F0);
      textColor = const Color(0xFF2D1B00);
    } else if (isDark) {
      bgColor = const Color(0xFF1A1A2E);
      textColor = const Color(0xFFE4E6EB);
    } else {
      bgColor = Colors.white;
      textColor = const Color(0xFF1A1A1A);
    }

    final totalChapters = widget.book.sections.fold<int>(
      0, (sum, s) => sum + s.chapters.length);
    final currentPos = widget.book.sections
        .take(_currentSection)
        .fold<int>(0, (sum, s) => sum + s.chapters.length) + _currentChapter + 1;
    final progress = currentPos / totalChapters;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Reading content
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                setState(() => _showControls = !_showControls);
                if (_showControls) {
                  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
                } else {
                  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
                }
              },
              onHorizontalDragEnd: (d) {
                if (d.primaryVelocity! < -80 && _hasNext) _goNext();
                if (d.primaryVelocity! > 80 && _hasPrev) _goPrev();
              },
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20, MediaQuery.of(context).viewPadding.top + 12, 20, 12),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(title, style: TextStyle(
                        fontSize: _fontSize + 2,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      )),
                    ),
                    Expanded(
                      child: content.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.auto_stories,
                                    size: 32, color: textColor.withAlpha(60)),
                                  const SizedBox(height: 12),
                                  Text('No content yet',
                                    style: TextStyle(
                                      color: textColor.withAlpha(100),
                                      fontSize: 14)),
                                  const SizedBox(height: 4),
                                  Text('This chapter is not yet available',
                                    style: TextStyle(
                                      color: textColor.withAlpha(60),
                                      fontSize: 12)),
                                ],
                              ),
                            )
                          : SingleChildScrollView(
                              controller: _scrollController,
                              child: Text(content, style: TextStyle(
                                fontSize: _fontSize,
                                height: _lineHeight,
                                color: textColor,
                              )),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Top bar
          if (_showControls)
            Container(
              padding: EdgeInsets.fromLTRB(
                4, MediaQuery.of(context).viewPadding.top + 4, 4, 0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withAlpha(160), Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _showToc = !_showToc),
                      child: Text(widget.book.title,
                        style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                        overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: _isBookmarked ? Colors.amber : Colors.white,
                    ),
                    onPressed: _toggleBookmark,
                  ),
                  IconButton(
                    icon: Icon(
                      _searchMode ? Icons.close : Icons.search,
                      color: Colors.white,
                    ),
                    onPressed: () => setState(() {
                      _searchMode = !_searchMode;
                      if (!_searchMode) {
                        _searchQuery = ''; _searchResults = [];
                        _searchController.clear();
                      }
                    }),
                  ),
                  IconButton(
                    icon: const Icon(Icons.text_fields, color: Colors.white),
                    onPressed: () => _showSettingsSheet(context),
                  ),
                ],
              ),
            ),

          // Table of contents
          if (_showToc)
            Positioned(
              top: MediaQuery.of(context).viewPadding.top + 56,
              left: 0, right: 0, bottom: 0,
              child: Container(
                color: bgColor.withAlpha(245),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      color: bgColor,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text('Table of Contents',
                              style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 16, color: textColor)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() => _showToc = false),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: widget.book.sections.length,
                        itemBuilder: (_, si) {
                          final section = widget.book.sections[si];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (section.title.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                                  child: Text(section.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14, color: textColor)),
                                ),
                              ...section.chapters.asMap().entries.map((entry) {
                                final ci = entry.key;
                                final ch = entry.value;
                                final isActive = si == _currentSection && ci == _currentChapter;
                                return ListTile(
                                  dense: true,
                                  selected: isActive,
                                  selectedTileColor: Colors.blue.withAlpha(20),
                                  title: Text('Chapter ${ch.number}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isActive
                                          ? Theme.of(context).colorScheme.primary
                                          : textColor.withAlpha(180),
                                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                                    )),
                                  onTap: () => _goTo(si, ci),
                                );
                              }),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Search overlay
          if (_searchMode)
            Positioned(
              top: MediaQuery.of(context).viewPadding.top + 56,
              left: 16, right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search entire book...',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                      prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.white54, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() { _searchQuery = ''; _searchResults = []; });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.black.withAlpha(200),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    ),
                    onChanged: _doSearch,
                    onSubmitted: _doSearch,
                  ),
                  if (_searchResults.isNotEmpty)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 250),
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(220),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        itemBuilder: (_, i) => ListTile(
                          dense: true,
                          title: Text(_searchResults[i].text,
                            style: const TextStyle(color: Colors.white, fontSize: 13)),
                          subtitle: Text(
                            '${widget.book.sections[_searchResults[i].section].title} ${_searchResults[i].chapter + 1}',
                            style: const TextStyle(color: Colors.white38, fontSize: 11),
                          ),
                          onTap: () => _goToResult(_searchResults[i]),
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // Progress bar
          Positioned(
            top: MediaQuery.of(context).viewPadding.top + 48,
            left: 0, right: 0,
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withAlpha(30),
              valueColor: AlwaysStoppedAnimation<Color>(
                _showControls ? Colors.white.withAlpha(180) : Colors.transparent),
              minHeight: 2,
            ),
          ),

          // Bottom bar
          if (_showControls)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 4, top: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withAlpha(160), Colors.transparent],
                  ),
                ),
                child: Column(
                  children: [
                    // Bookmark indicator
                    if (_bookmarks.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: SizedBox(
                          height: 28,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            children: _bookmarks.map((bm) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ActionChip(
                                  avatar: const Icon(Icons.bookmark, size: 12, color: Colors.amber),
                                  label: Text('${bm['sectionTitle']} ${bm['chapterNumber']}',
                                    style: const TextStyle(fontSize: 10, color: Colors.white)),
                                  backgroundColor: Colors.white.withAlpha(30),
                                  onPressed: () => _goTo(
                                    bm['section'] as int, bm['chapter'] as int),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.chevron_left, color: Colors.white70, size: 22),
                          label: const Text('Prev',
                            style: TextStyle(color: Colors.white70, fontSize: 14)),
                          onPressed: _hasPrev ? _goPrev : null,
                        ),
                        Text('${_chapter.number} / ${_section.chapters.length}',
                          style: const TextStyle(color: Colors.white54, fontSize: 13)),
                        TextButton.icon(
                          icon: const Icon(Icons.chevron_right, color: Colors.white70, size: 22),
                          label: const Text('Next',
                            style: TextStyle(color: Colors.white70, fontSize: 14)),
                          onPressed: _hasNext ? _goNext : null,
                        ),
                      ],
                    ),
                    Text('$currentPos / $totalChapters · ${widget.book.title}',
                      style: const TextStyle(color: Colors.white30, fontSize: 10)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchResult {
  final int section, chapter;
  final String text;
  _SearchResult({required this.section, required this.chapter, required this.text});
}
