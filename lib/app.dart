import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'config/globals.dart';
import 'screens/home_screen.dart';
import 'screens/translate_screen.dart';
import 'screens/conversation_screen.dart';
import 'screens/library_screen.dart';
import 'screens/settings_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  String? _sourceLang;
  String? _targetLang;

  @override
  void initState() {
    super.initState();
    tabNotifier.addListener(_onTabRequest);
  }

  @override
  void dispose() {
    tabNotifier.removeListener(_onTabRequest);
    super.dispose();
  }

  void _onTabRequest() {
    final req = tabNotifier.value;
    if (req == null) return;
    tabNotifier.value = null; // consume
    setState(() {
      _currentIndex = req.index;
      _sourceLang = req.sourceLang;
      _targetLang = req.targetLang;
    });
    if (req.index == 1) {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const HomeScreen(),
          TranslateScreen(
            key: ValueKey('$_sourceLang-$_targetLang'),
            initialSource: _sourceLang,
            initialTarget: _targetLang,
          ),
          const ConversationScreen(),
          const LibraryScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() {
          _currentIndex = i;
          _sourceLang = null;
          _targetLang = null;
        }),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.translate_outlined), selectedIcon: Icon(Icons.translate), label: 'Translate'),
          NavigationDestination(icon: Icon(Icons.chat_outlined), selectedIcon: Icon(Icons.chat), label: 'Chat'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Library'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
