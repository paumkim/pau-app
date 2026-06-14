import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/translation_cache.dart';
import '../services/phrasebook.dart';
import '../services/book_registry.dart';
import '../models/book_content.dart';
import 'translate_screen.dart';
import 'vocab_screen.dart';
import 'phrasebook_screen.dart';
import 'plugins/reader_screen.dart';
import '../services/plugin_screens.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  List<_SearchResult> _results = [];
  bool _searched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() { _results = []; _searched = false; });
      return;
    }

    final q = query.toLowerCase().trim();
    final results = <_SearchResult>[];

    // Search translation cache
    final cacheEntries = await TranslationCache.search(q);
    for (final e in cacheEntries) {
      results.add(_SearchResult(
        type: _ResultType.translation,
        title: e['sourceText'] ?? '',
        subtitle: e['translatedText'] ?? '',
        icon: Icons.translate,
        color: AppTheme.primary,
      ));
    }

    // Search phrasebook
    for (final cat in Phrasebook.categories) {
      for (final phrase in cat.phrases) {
        if (phrase.english.toLowerCase().contains(q) ||
            phrase.zomi.toLowerCase().contains(q)) {
          results.add(_SearchResult(
            type: _ResultType.phrase,
            title: phrase.english,
            subtitle: phrase.zomi,
            icon: cat.icon,
            color: AppTheme.accent,
            category: cat.name,
          ));
        }
      }
    }

    // Search books
    for (final book in BookRegistry.books) {
      for (var si = 0; si < book.sections.length; si++) {
        final section = book.sections[si];
        if (section.title.toLowerCase().contains(q)) {
          results.add(_SearchResult(
            type: _ResultType.book,
            title: '${book.title} › ${section.title}',
            subtitle: 'Section',
            icon: Icons.menu_book,
            color: const Color(0xFF8B4513),
            bookId: book.id,
            book: book,
            section: si,
          ));
        }
        for (var ci = 0; ci < section.chapters.length; ci++) {
          final chapter = section.chapters[ci];
          if (chapter.content.toLowerCase().contains(q)) {
            final preview = chapter.content
                .substring(0, chapter.content.length.clamp(0, 100))
                .replaceAll('\n', ' ');
            results.add(_SearchResult(
              type: _ResultType.book,
              title: '${book.title} › ${section.title} ${chapter.number}',
              subtitle: preview,
              icon: Icons.menu_book,
              color: const Color(0xFF8B4513),
              bookId: book.id,
              book: book,
              section: si,
              chapter: ci,
            ));
          }
        }
      }
    }

    // Limit results
    if (results.length > 50) results.removeRange(50, results.length);

    setState(() {
      _results = results;
      _searched = true;
    });
  }

  void _openResult(_SearchResult r) {
    switch (r.type) {
      case _ResultType.translation:
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const VocabScreen(),
        ));
        break;
      case _ResultType.phrase:
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const PhrasebookScreen(),
        ));
        break;
      case _ResultType.book:
        if (r.bookId == 'tedim_bible') {
          final screen = PluginScreens.open('tedim_bible');
          if (screen != null) {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
          }
        } else if (r.book != null) {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ReaderScreen(book: r.book!),
          ));
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 8, 16, 8),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search translations, books, phrases...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _search('');
                        },
                      )
                    : null,
              ),
              onChanged: _search,
            ),
          ),
          Expanded(
            child: _results.isEmpty && _searched
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off,
                          size: 48, color: AppTheme.textSecondaryLight.withAlpha(80)),
                        const SizedBox(height: 12),
                        Text('No results found',
                          style: TextStyle(color: AppTheme.textSecondaryLight)),
                      ],
                    ),
                  )
                : _results.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search,
                              size: 48, color: AppTheme.primary.withAlpha(80)),
                            const SizedBox(height: 12),
                            Text('Search everything in Pau',
                              style: TextStyle(color: AppTheme.textSecondaryLight)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _results.length,
                        itemBuilder: (_, i) {
                          final r = _results[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundColor: r.color.withAlpha(25),
                                child: Icon(r.icon, color: r.color, size: 16),
                              ),
                              title: Text(r.title,
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                              subtitle: Text(
                                r.category != null
                                    ? '${r.subtitle} · ${r.category}'
                                    : r.subtitle,
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12)),
                              trailing: const Icon(Icons.chevron_right, size: 16),
                              onTap: () => _openResult(r),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

enum _ResultType { translation, phrase, book }

class _SearchResult {
  final _ResultType type;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? category;
  final String? bookId;
  final BookContent? book;
  final int? section;
  final int? chapter;

  _SearchResult({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.category,
    this.bookId,
    this.book,
    this.section,
    this.chapter,
  });
}
