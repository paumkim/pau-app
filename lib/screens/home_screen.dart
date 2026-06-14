import 'package:flutter/material.dart';
import '../config/globals.dart';
import '../theme/app_theme.dart';
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
    final allPlugins = PluginRegistry.plugins;
    final enabled = PluginRegistry.enabledPlugins;
    final available = PluginRegistry.disabledPlugins;

    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Icon(Icons.translate, size: 36,
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
                trailing: Icon(Icons.chevron_right, size: 16,
                  color: AppTheme.textSecondaryLight.withAlpha(80)),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SearchScreen())),
              ),
            ),
            const SizedBox(height: 20),

            // Quick translate
            Text('Translate',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _quickCard('Zomi ↔ English', 'For work, school, daily life', () {
              tabNotifier.value = const TabRequest(1, sourceLang: 'zomi', targetLang: 'en');
            }),
            const SizedBox(height: 6),
            _quickCard('Zomi ↔ Malay', 'For Malaysia diaspora', () {
              tabNotifier.value = const TabRequest(1, sourceLang: 'zomi', targetLang: 'ms');
            }),
            const SizedBox(height: 6),
            _quickCard('Zomi ↔ Chinese', 'For Myanmar Zomi community', () {
              tabNotifier.value = const TabRequest(1, sourceLang: 'zomi', targetLang: 'zh');
            }),

            const SizedBox(height: 24),

            // Available plugins — things to discover
            if (available.isNotEmpty) ...[
              Text('Discover',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...available.map((p) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: p.color.withAlpha(25),
                    child: Icon(p.icon, color: p.color, size: 18),
                  ),
                  title: Text(p.name,
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                  subtitle: Text(p.description, style: const TextStyle(fontSize: 12)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('GET',
                      style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600,
                        color: AppTheme.primary)),
                  ),
                  onTap: () async {
                    await PluginRegistry.toggle(p);
                    setState(() {});
                  },
                ),
              )),
            ],

            const SizedBox(height: 24),

            // Your plugins (already installed)
            if (enabled.isNotEmpty) ...[
              Text('Your Plugins',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...enabled.map((p) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: p.color.withAlpha(25),
                    child: Icon(p.icon, color: p.color, size: 18),
                  ),
                  title: Text(p.name,
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                  subtitle: Text('Tap to open', style: const TextStyle(fontSize: 12)),
                  trailing: Icon(Icons.check_circle, size: 18, color: AppTheme.primary),
                  onTap: () => _openPlugin(context, p.id),
                ),
              )),
            ],

            const SizedBox(height: 12),
            // Quick links
            Text('Learn',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _quickLink('Vocabulary Builder', 'Flashcards from your translations', Icons.auto_stories, AppTheme.accent, () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VocabScreen()));
            }),
            const SizedBox(height: 6),
            _quickLink('Zomi Phrases', 'Common phrases by category', Icons.forum, AppTheme.primary, () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PhrasebookScreen()));
            }),
          ],
        ),
      ),
    );
  }

  Widget _quickCard(String title, String subtitle, VoidCallback onTap) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primary.withAlpha(20),
          child: Icon(Icons.translate, color: AppTheme.primary, size: 18),
        ),
        title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: Icon(Icons.arrow_forward_ios, size: 12,
          color: AppTheme.textSecondaryLight.withAlpha(80)),
        onTap: onTap,
      ),
    );
  }

  Widget _quickLink(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withAlpha(20),
          child: Icon(icon, color: color, size: 18),
        ),
        title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: Icon(Icons.arrow_forward_ios, size: 12,
          color: AppTheme.textSecondaryLight.withAlpha(80)),
        onTap: onTap,
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
