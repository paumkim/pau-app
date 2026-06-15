import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/app_theme.dart';
import '../services/book_registry.dart';
import '../services/epub_parser.dart';
import '../services/plugin_registry.dart';
import '../services/plugin_screens.dart';
import '../widgets/error_widgets.dart';
import 'vocab_screen.dart';
import 'phrasebook_screen.dart';
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
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await PluginRegistry.reload();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = PluginRegistry.enabledPlugins;

    return Scaffold(
      body: _loading
          ? const AppLoadingShimmer(itemCount: 4)
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
              children: [
                // Header
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withAlpha(12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.menu_book, size: 28, color: AppTheme.primary),
                      ),
                      const SizedBox(height: 8),
                      Text('My Library',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600)),
                      Text('${enabled.length} plugins · ${BookRegistry.books.length} books',
                        style: TextStyle(fontSize: 13,
                          color: AppTheme.textSecondaryLight)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Import EPUB
                Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primary.withAlpha(20),
                      child: const Icon(Icons.file_open, color: AppTheme.primary, size: 20),
                    ),
                    title: const Text('Import EPUB',
                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                    subtitle: const Text('Add an ebook from your device',
                      style: TextStyle(fontSize: 12)),
                    trailing: _importing
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(Icons.add, size: 18,
                            color: AppTheme.textSecondaryLight.withAlpha(120)),
                    onTap: _importing ? null : _openEpubPicker,
                  ),
                ),
                const SizedBox(height: 20),

                // My Books
                if (BookRegistry.books.isNotEmpty) ...[
                  Text('My Books',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13,
                      color: AppTheme.primary)),
                  const SizedBox(height: 8),
                  ...BookRegistry.books.map((book) => Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: AppTheme.primary.withAlpha(20),
                        child: const Icon(Icons.menu_book, color: AppTheme.primary, size: 18),
                      ),
                      title: Text(book.title,
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                      subtitle: Text(book.author.isNotEmpty
                          ? book.author
                          : '${book.sections.length} sections',
                        style: const TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right, size: 18),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ReaderScreen(book: book),
                      )),
                    ),
                  )),
                  const SizedBox(height: 20),
                ],

                // Installed Plugins
                if (enabled.isNotEmpty) ...[
                  Text('Installed',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13,
                      color: AppTheme.primary)),
                  const SizedBox(height: 8),
                  ...enabled.map((p) => Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: p.color.withAlpha(25),
                        child: Icon(p.icon, color: p.color, size: 18),
                      ),
                      title: Text(p.name,
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                      subtitle: Text(p.description, style: const TextStyle(fontSize: 12)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, size: 18, color: AppTheme.primary),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right, size: 18),
                        ],
                      ),
                      onTap: () => _openPlugin(context, p.id),
                    ),
                  )),
                  const SizedBox(height: 20),
                ],

                // Vocabulary
                Text('Learning',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13,
                    color: AppTheme.primary)),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.accent.withAlpha(20),
                      child: const Icon(Icons.auto_stories, color: AppTheme.accent, size: 18),
                    ),
                    title: const Text('Vocabulary',
                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                    subtitle: const Text('Flashcards from your translations',
                      style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const VocabScreen())),
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primary.withAlpha(20),
                      child: const Icon(Icons.forum, color: AppTheme.primary, size: 18),
                    ),
                    title: const Text('Zomi Phrases',
                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                    subtitle: const Text('Common phrases by category',
                      style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PhrasebookScreen())),
                  ),
                ),
              ],
            ),
    );
  }

  void _openPlugin(BuildContext context, String id) {
    final screen = PluginScreens.open(id);
    if (screen == null) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _openEpubPicker() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['epub'],
      );
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not read this EPUB file'),
              duration: Duration(seconds: 2)),
          );
        }
        return;
      }

      if (mounted) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ReaderScreen(book: book),
        ));
      }
    } catch (e) {
      setState(() => _importing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString().substring(0, 80)}'),
            duration: Duration(seconds: 3)),
        );
      }
    }
  }
}
