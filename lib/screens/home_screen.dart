import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/plugin.dart';
import '../config/globals.dart';
import '../services/plugin_registry.dart';
import 'translate_screen.dart';
import 'vocab_screen.dart';
import 'phrasebook_screen.dart';
import 'search_screen.dart';
import '../services/plugin_screens.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final enabled = PluginRegistry.enabledPlugins;

    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Icon(Icons.translate, size: 40,
                color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text('Your Zomi language companion',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryLight)),
            ),
            const SizedBox(height: 16),

            // Search bar
            Card(
              child: ListTile(
                leading: Icon(Icons.search, size: 20,
                  color: AppTheme.textSecondaryLight),
                title: Text('Search translations, books, phrases...',
                  style: TextStyle(fontSize: 14,
                    color: AppTheme.textSecondaryLight)),
                trailing: const Icon(Icons.chevron_right, size: 18),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SearchScreen())),
              ),
            ),
            const SizedBox(height: 16),

            Text('Translate',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _quickCard(context, 'Zomi ↔ English',
              'For work, school, daily life', AppTheme.primary, () {
              tabNotifier.value = const TabRequest(1, sourceLang: 'zomi', targetLang: 'en');
            }),
            const SizedBox(height: 6),
            _quickCard(context, 'Zomi ↔ Malay',
              'For Malaysia diaspora', AppTheme.primary, () {
              tabNotifier.value = const TabRequest(1, sourceLang: 'zomi', targetLang: 'ms');
            }),
            const SizedBox(height: 6),
            _quickCard(context, 'Zomi ↔ Chinese',
              'For Myanmar Zomi community', AppTheme.accent, () {
              tabNotifier.value = const TabRequest(1, sourceLang: 'zomi', targetLang: 'zh');
            }),

            const SizedBox(height: 24),
            Text('Learn',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _quickCard(context, 'Vocabulary Builder',
              'Swipeable flashcards from your saved translations',
              AppTheme.accent, () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const VocabScreen(),
              ));
            }),
            const SizedBox(height: 6),
            _quickCard(context, 'Zomi Phrases',
              'Common phrases organized by category', AppTheme.primary, () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const PhrasebookScreen(),
              ));
            }),

            if (enabled.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('My Plugins',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...enabled.map((p) => _pluginCard(context, p)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _quickCard(BuildContext context, String title, String subtitle,
      Color color, VoidCallback onTap) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withAlpha(25),
          child: Icon(Icons.translate, color: color, size: 18),
        ),
        title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, size: 18),
        onTap: onTap,
      ),
    );
  }

  Widget _pluginCard(BuildContext context, PauPlugin plugin) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: plugin.color.withAlpha(25),
          child: Icon(plugin.icon, color: plugin.color, size: 18),
        ),
        title: Text(plugin.name,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        subtitle: Text(plugin.description, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, size: 18),
        onTap: () => _openPlugin(context, plugin.id),
      ),
    );
  }

  void _openPlugin(BuildContext context, String id) {
    final screen = PluginScreens.open(id);
    if (screen == null) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
