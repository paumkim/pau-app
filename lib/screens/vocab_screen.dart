import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/translation_cache.dart';

class VocabScreen extends StatefulWidget {
  const VocabScreen({super.key});

  @override
  State<VocabScreen> createState() => _VocabScreenState();
}

class _VocabScreenState extends State<VocabScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, String>> _entries = [];
  List<Map<String, String>> _filteredEntries = [];
  bool _loading = true;
  String _filterLanguage = 'all';
  int _currentCard = 0;
  bool _showAnswer = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final entries = await TranslationCache.getAllEntries();
    if (mounted) setState(() {
      _entries = entries;
      _filteredEntries = entries;
      _loading = false;
      _currentCard = 0;
      _showAnswer = false;
    });
  }

  void _applyFilter(String language) {
    setState(() {
      _filterLanguage = language;
      if (language == 'all') {
        _filteredEntries = List.from(_entries);
      } else {
        _filteredEntries = _entries.where((e) =>
          e['targetLanguage'] == language ||
          e['sourceLanguage'] == language
        ).toList();
      }
      _currentCard = 0;
      _showAnswer = false;
    });
  }

  void _nextCard() {
    if (_currentCard < _filteredEntries.length - 1) {
      setState(() {
        _currentCard++;
        _showAnswer = false;
      });
    }
  }

  void _prevCard() {
    if (_currentCard > 0) {
      setState(() {
        _currentCard--;
        _showAnswer = false;
      });
    }
  }

  void _shuffle() {
    setState(() {
      _filteredEntries.shuffle(Random());
      _currentCard = 0;
      _showAnswer = false;
    });
  }

  Set<String> get _availableLanguages {
    final langs = <String>{};
    for (final e in _entries) {
      if (e['sourceLanguage'] != null) langs.add(e['sourceLanguage']!);
      if (e['targetLanguage'] != null) langs.add(e['targetLanguage']!);
    }
    return langs;
  }

  String _languageName(String code) {
    switch (code) {
      case 'zomi': return 'Zomi';
      case 'en': return 'English';
      case 'ms': return 'Malay';
      case 'zh': return 'Chinese';
      default: return code;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context)),
                const SizedBox(width: 8),
                Text('Vocabulary',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('${_filteredEntries.length} words',
                  style: TextStyle(fontSize: 13,
                    color: AppTheme.textSecondaryLight)),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Flashcards'),
              Tab(text: 'Word List'),
            ],
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildFlashcards(),
                      _buildWordList(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlashcards() {
    if (_filteredEntries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.auto_stories,
                size: 48, color: AppTheme.primary.withAlpha(120)),
            ),
            const SizedBox(height: 20),
            const Text('No vocabulary yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Translate something to build your vocabulary.',
              style: TextStyle(color: AppTheme.textSecondaryLight)),
          ],
        ),
      );
    }

    final card = _filteredEntries[_currentCard];
    final progress = '${_currentCard + 1} / ${_filteredEntries.length}';

    return Column(
      children: [
        // Language filter chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('All', 'all'),
                ..._availableLanguages.map((l) => _filterChip(
                  _languageName(l), l)),
              ],
            ),
          ),
        ),
        // Card area
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _showAnswer = !_showAnswer),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 4,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _showAnswer
                            ? (card['translatedText'] ?? '')
                            : (card['sourceText'] ?? ''),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _showAnswer
                            ? _languageName(card['targetLanguage'] ?? '')
                            : _languageName(card['sourceLanguage'] ?? ''),
                        style: TextStyle(
                          color: AppTheme.textSecondaryLight,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_showAnswer)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _languageName(card['targetLanguage'] ?? ''),
                            style: TextStyle(
                              color: AppTheme.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      else
                        Text('Tap to reveal',
                          style: TextStyle(
                            color: AppTheme.textSecondaryLight,
                            fontSize: 13,
                          )),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // Progress + navigation
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(progress,
                style: TextStyle(
                  color: AppTheme.textSecondaryLight, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.skip_previous),
                    onPressed: _prevCard,
                    tooltip: 'Previous',
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.shuffle),
                    onPressed: _shuffle,
                    tooltip: 'Shuffle',
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.skip_next),
                    onPressed: _nextCard,
                    tooltip: 'Next',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = _filterLanguage == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(
          fontSize: 12,
          color: selected ? Colors.white : null,
        )),
        selected: selected,
        selectedColor: AppTheme.primary,
        onSelected: (_) => _applyFilter(value),
      ),
    );
  }

  Widget _buildWordList() {
    if (_filteredEntries.isEmpty) {
      return Center(
        child: Text('No saved words yet.',
          style: TextStyle(color: AppTheme.textSecondaryLight)),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search your vocabulary...',
              prefixIcon: const Icon(Icons.search, size: 20),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
            onChanged: (q) {
              setState(() {
                if (q.isEmpty) {
                  _applyFilter(_filterLanguage);
                } else {
                  _filteredEntries = _entries.where((e) =>
                    (e['sourceText'] ?? '').toLowerCase().contains(q.toLowerCase()) ||
                    (e['translatedText'] ?? '').toLowerCase().contains(q.toLowerCase())
                  ).toList();
                }
              });
            },
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _filteredEntries.length,
            itemBuilder: (_, i) {
              final e = _filteredEntries[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 4),
                child: ListTile(
                  dense: true,
                  title: Text(e['sourceText'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w500,
                      fontSize: 14)),
                  subtitle: Text(e['translatedText'] ?? '',
                    style: TextStyle(color: AppTheme.primary, fontSize: 13)),
                  trailing: Text(
                    '${_languageName(e['sourceLanguage'] ?? '')} → '
                    '${_languageName(e['targetLanguage'] ?? '')}',
                    style: TextStyle(fontSize: 11,
                      color: AppTheme.textSecondaryLight)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
