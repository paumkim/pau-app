import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/app_theme.dart';
import '../models/book_content.dart';
import '../models/plugin.dart';
import '../services/book_registry.dart';
import '../services/epub_parser.dart';
import '../services/hive_storage.dart';
import '../services/plugin_registry.dart';
import '../services/plugin_screens.dart';
import '../services/translation_cache.dart';
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
    final disabled = PluginRegistry.disabledPlugins;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const AppLoadingShimmer(itemCount: 4)
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                children: [
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
                        Text('Library',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600)),
                        Text('${enabled.length} of ${enabled.length + disabled.length} plugins active',
                          style: TextStyle(fontSize: 13,
                            color: AppTheme.textSecondaryLight)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primary.withAlpha(20),
                        child: const Icon(Icons.file_open, color: AppTheme.primary, size: 20),
                      ),
                      title: const Text('Open EPUB from device',
                        style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                      subtitle: const Text('Pick an ebook file from your phone',
                        style: TextStyle(fontSize: 12)),
                      trailing: _importing
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.chevron_right, size: 18),
                      onTap: _importing ? null : _openEpubPicker,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Learning tools
                  Text('Learn',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13,
                      color: AppTheme.primary)),
                  const SizedBox(height: 8),
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.accent.withAlpha(20),
                        child: const Icon(Icons.auto_stories, color: AppTheme.accent, size: 18),
                      ),
                      title: const Text('Vocabulary Builder',
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
                        child: const Icon(Icons.translate, color: AppTheme.primary, size: 18),
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
                  const SizedBox(height: 16),

                  if (enabled.isNotEmpty) ...[
                    Text('Installed',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13,
                        color: AppTheme.primary)),
                    const SizedBox(height: 8),
                    ...enabled.map((p) => _pluginCard(context, p, true)),
                    const SizedBox(height: 24),
                  ],

                  if (disabled.isNotEmpty) ...[
                    Text('Available',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13,
                        color: AppTheme.textSecondaryLight)),
                    const SizedBox(height: 8),
                    ...disabled.map((p) => _pluginCard(context, p, false)),
                    const SizedBox(height: 24),
                  ],

                  if (BookRegistry.books.isNotEmpty) ...[
                    Text('My Books',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13,
                        color: AppTheme.primary)),
                    const SizedBox(height: 8),
                    ...BookRegistry.books.map((book) => _bookCard(context, book)),
                    const SizedBox(height: 24),
                  ],

                  Text('Recent Activity',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13,
                      color: AppTheme.primary)),
                  const SizedBox(height: 8),
                  _buildHistory(context),
                ],
              ),
      ),
    );
  }

  Widget _pluginCard(BuildContext context, PauPlugin plugin, bool installed) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: plugin.color.withAlpha(25),
          child: Icon(plugin.icon, color: plugin.color, size: 18),
        ),
        title: Text(plugin.name,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        subtitle: Text(plugin.description, style: const TextStyle(fontSize: 12)),
        trailing: installed
            ? Icon(Icons.check_circle, color: AppTheme.primary, size: 20)
            : Text('Get',
                style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
        onTap: () async {
          if (!installed) {
            await PluginRegistry.toggle(plugin);
            _load();
            return;
          }
          _openPlugin(context, plugin.id);
        },
      ),
    );
  }

  Widget _buildHistory(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: HiveStorage.isAvailable
          ? HiveStorage.getChatHistory()
          : _legacyGetHistory(),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppLoadingShimmer(itemCount: 2, height: 50);
        }
        if (items.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Text('No recent activity',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondaryLight, fontSize: 13)),
          );
        }
        return Column(
          children: items.take(5).map((item) {
            final text = item['text'] as String? ?? '';
            final isUser = item['isUser'] as bool? ?? true;
            return Card(
              margin: const EdgeInsets.only(bottom: 4),
              child: ListTile(
                dense: true,
                leading: Icon(
                  isUser ? Icons.person : Icons.smart_toy_outlined,
                  size: 16,
                  color: isUser ? AppTheme.primary : AppTheme.accent,
                ),
                title: Text(text,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13)),
                trailing: IconButton(
                  icon: const Icon(Icons.copy, size: 14),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied'),
                        duration: Duration(seconds: 1)),
                    );
                  },
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _legacyGetHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('pau_chat_history');
      if (raw == null) return [];
      return (jsonDecode(raw) as List).cast<Map<String, dynamic>>().reversed.toList();
    } catch (_) {
      return [];
    }
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

      // Copy to temp dir to handle content URIs
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/${result.files.first.name}');
      await tempFile.writeAsBytes(await File(filePath).readAsBytes());

      // Parse EPUB (runs on main isolate but shows loading state now)
      final book = await EpubParser.openFile(tempFile.path);

      // Clean up temp file
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

  Widget _bookCard(BuildContext context, BookContent book) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: AppTheme.primary.withAlpha(20),
          child: const Icon(Icons.menu_book, color: AppTheme.primary, size: 18),
        ),
        title: Text(book.title,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        subtitle: Text(book.author.isNotEmpty ? book.author : '${book.sections.length} sections',
          style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, size: 18),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ReaderScreen(book: book),
        )),
      ),
    );
  }
}
