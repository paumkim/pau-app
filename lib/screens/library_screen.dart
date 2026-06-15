import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/app_theme.dart';
import '../services/book_registry.dart';
import '../services/epub_parser.dart';
import '../services/bible_loader.dart';
import '../services/plugin_registry.dart';
import '../services/plugin_screens.dart';
import '../services/lyrics_loader.dart';
import '../widgets/error_widgets.dart';
import 'vocab_screen.dart';
import 'phrasebook_screen.dart';
import 'plugins/bible_reader_screen.dart';
import 'plugins/lyrics_screen.dart';
import 'plugins/reader_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  bool _loading = true;
  bool _importing = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    await PluginRegistry.reload();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final bibles = BibleLoader.translations;
    final books = BookRegistry.books;
    final hasLyrics = LyricsLoader.songs.isNotEmpty;
    final plugins = PluginRegistry.enabledPlugins.where((p) => p.id != 'tedim_bible' && p.id != 'zomi_lyrics').toList();

    return Scaffold(
      body: _loading
          ? const AppLoadingShimmer(itemCount: 4)
          : ListView(padding: const EdgeInsets.fromLTRB(16, 24, 16, 32), children: [
              Center(child: Column(children: [
                Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppTheme.primary.withAlpha(12), shape: BoxShape.circle),
                  child: const Icon(Icons.menu_book, size: 28, color: AppTheme.primary)),
                const SizedBox(height: 8),
                Text('My Library', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                Text('${bibles.length} Bibles  ·  ${books.length} books  ·  ${hasLyrics ? LyricsLoader.songs.length : 0} songs', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondaryLight)),
              ])),
              const SizedBox(height: 24),

              // My Books — imported EPUBs + bundled books
              if (books.isNotEmpty) ...[
                _sectionHeader('My Books', Icons.menu_book),
                const SizedBox(height: 8),
                ...books.map((book) => Card(margin: const EdgeInsets.only(bottom: 6), child: ListTile(
                  leading: CircleAvatar(radius: 18, backgroundColor: AppTheme.primary.withAlpha(20),
                    child: const Icon(Icons.menu_book, color: AppTheme.primary, size: 18)),
                  title: Text(book.title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                  subtitle: Text(book.author.isNotEmpty ? book.author : '${book.sections.length} sections', style: const TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ReaderScreen(book: book))),
                ))),
                const SizedBox(height: 20),
              ],

              // Import button (always visible)
              if (books.isEmpty)
                _sectionHeader('My Books', Icons.menu_book),
              Card(child: ListTile(
                leading: CircleAvatar(backgroundColor: AppTheme.primary.withAlpha(20),
                  child: const Icon(Icons.file_open, color: AppTheme.primary, size: 20)),
                title: const Text('Import EPUB', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                subtitle: const Text('Add an ebook from your device', style: const TextStyle(fontSize: 12)),
                trailing: _importing
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(Icons.add, size: 18, color: AppTheme.textSecondaryLight.withAlpha(120)),
                onTap: _importing ? null : _openEpubPicker,
              )),
              const SizedBox(height: 20),

              // Bibles
              _sectionHeader('Bibles', Icons.auto_stories),
              const SizedBox(height: 8),
              ...bibles.map((b) => Card(child: ListTile(
                leading: CircleAvatar(radius: 18, backgroundColor: AppTheme.primary.withAlpha(20),
                  child: const Icon(Icons.auto_stories, color: AppTheme.primary, size: 18)),
                title: Text(b.name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                subtitle: Text('${b.language}  ·  ${b.totalVerses} verses', style: const TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right, size: 18),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BibleReaderScreen())),
              ))),
              const SizedBox(height: 20),

              // Songs
              if (hasLyrics) ...[
                _sectionHeader('Songs', Icons.music_note),
                const SizedBox(height: 8),
                Card(child: ListTile(
                  leading: CircleAvatar(radius: 18, backgroundColor: AppTheme.accent.withAlpha(25),
                    child: const Icon(Icons.music_note, color: AppTheme.accent, size: 18)),
                  title: const Text('Zomi Lyrics', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                  subtitle: Text('${LyricsLoader.songs.length} songs', style: const TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LyricsScreen())),
                )),
                const SizedBox(height: 20),
              ],

              // Learning
              _sectionHeader('Learning', Icons.auto_stories),
              const SizedBox(height: 8),
              Card(child: ListTile(
                leading: CircleAvatar(backgroundColor: AppTheme.accent.withAlpha(20),
                  child: const Icon(Icons.auto_stories, color: AppTheme.accent, size: 18)),
                title: const Text('Vocabulary', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                subtitle: const Text('Flashcards from your translations', style: const TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right, size: 18),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VocabScreen())),
              )),
              Card(child: ListTile(
                leading: CircleAvatar(backgroundColor: AppTheme.primary.withAlpha(20),
                  child: const Icon(Icons.forum, color: AppTheme.primary, size: 18)),
                title: const Text('Zomi Phrases', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                subtitle: const Text('Common phrases by category', style: const TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right, size: 18),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PhrasebookScreen())),
              )),

              // Other plugins
              if (plugins.isNotEmpty) ...[
                const SizedBox(height: 20),
                _sectionHeader('Plugins', Icons.extension),
                const SizedBox(height: 8),
                ...plugins.map((p) => Card(margin: const EdgeInsets.only(bottom: 6), child: ListTile(
                  leading: CircleAvatar(radius: 18, backgroundColor: p.color.withAlpha(25),
                    child: Icon(p.icon, color: p.color, size: 18)),
                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                  subtitle: Text('Tap to open', style: const TextStyle(fontSize: 12)),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.check_circle, size: 18, color: AppTheme.primary),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, size: 18),
                  ]),
                  onTap: () => _openPlugin(context, p.id),
                ))),
              ],
            ]),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(children: [
      Icon(icon, size: 16, color: AppTheme.primary),
      const SizedBox(width: 6),
      Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.primary)),
    ]);
  }

  void _openPlugin(BuildContext context, String id) {
    final screen = PluginScreens.open(id);
    if (screen == null) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _openEpubPicker() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['epub']);
      if (result == null || result.files.isEmpty) return;
      final filePath = result.files.first.path;
      if (filePath == null) return;
      setState(() => _importing = true);
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/${result.files.first.name}');
      await tempFile.writeAsBytes(await File(filePath).readAsBytes());
      final book = await EpubParser.openFile(tempFile.path);
      try { await tempFile.delete(); } catch (_) {}
      setState(() => _importing = false);
      if (book == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not read this EPUB file'), duration: Duration(seconds: 2)));
        return;
      }
      if (mounted) Navigator.of(context).push(MaterialPageRoute(builder: (_) => ReaderScreen(book: book)));
    } catch (e) {
      setState(() => _importing = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString().substring(0, 80)}'), duration: Duration(seconds: 3)));
    }
  }
}
