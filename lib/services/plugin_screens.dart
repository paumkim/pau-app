import 'package:flutter/material.dart';
import '../screens/plugins/bible_reader_screen.dart';
import '../screens/plugins/lyrics_screen.dart';
import '../screens/plugins/daily_verse.dart';

/// ONE registry that maps plugin IDs to their screen widgets.
/// Adding a new plugin = add one line here + one entry in plugins.json.
/// No more switch statements scattered across 3 files.
class PluginScreens {
  PluginScreens._();

  static final Map<String, Widget Function()> _registry = {
    'tedim_bible': () => const BibleReaderScreen(),
    'zomi_lyrics': () => const LyricsScreen(),
    'daily_verse': () => const DailyVerseScreen(),
  };

  /// Returns the screen widget for a plugin, or null if not found.
  static Widget? open(String pluginId) => _registry[pluginId]?.call();

  static bool has(String pluginId) => _registry.containsKey(pluginId);

  static Set<String> get registeredIds => _registry.keys.toSet();
}
