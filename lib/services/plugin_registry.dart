import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/plugin.dart';

class PluginRegistry {
  static List<PauPlugin>? _plugins;
  static const _pluginKey = 'pau_plugins';

  static List<PauPlugin> get plugins {
    if (_plugins == null) return [];
    return List.unmodifiable(_plugins!);
  }

  static List<PauPlugin> get enabledPlugins {
    if (_plugins == null) return [];
    return _plugins!.where((p) => p.enabled).toList();
  }

  static List<PauPlugin> get disabledPlugins {
    if (_plugins == null) return [];
    return _plugins!.where((p) => !p.enabled).toList();
  }

  static Future<void> loadAll() async {
    try {
      final jsonString = await rootBundle.loadString('assets/plugins/plugins.json');
      final list = jsonDecode(jsonString) as List;
      _plugins = list.map((json) => PauPlugin(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        icon: _iconFromString(json['icon'] as String),
        color: Color(int.parse((json['color'] as String).replaceAll('#', '0xFF'))),
        type: json['type'] as String,
        enabled: json['defaultEnabled'] as bool? ?? false,
      )).toList();

      await _loadStates();
    } catch (e) {
      debugPrint('Failed to load plugins: $e');
      _plugins = [];
    }
  }

  static IconData _iconFromString(String name) {
    switch (name) {
      case 'menu_book': return Icons.menu_book;
      case 'music_note': return Icons.music_note;
      case 'wb_sunny': return Icons.wb_sunny;
      case 'translate': return Icons.translate;
      case 'chat': return Icons.chat;
      case 'settings': return Icons.settings;
      case 'home': return Icons.home;
      case 'extension': return Icons.extension;
      default: return Icons.extension;
    }
  }

  static Future<void> _loadStates() async {
    if (_plugins == null) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pluginKey);

    if (raw == null || raw.isEmpty) {
      final defaultIds = _plugins!.where((p) => p.enabled).map((p) => p.id).join(',');
      await prefs.setString(_pluginKey, defaultIds);
      return;
    }

    final enabledIds = raw.split(',').toSet();
    for (var p in _plugins!) {
      if (p.enabled) enabledIds.add(p.id);
    }
    await prefs.setString(_pluginKey, enabledIds.join(','));

    for (var p in _plugins!) {
      p.enabled = enabledIds.contains(p.id);
    }
  }

  static Future<void> toggle(PauPlugin plugin) async {
    if (_plugins == null) return;
    plugin.enabled = !plugin.enabled;
    final prefs = await SharedPreferences.getInstance();
    final ids = _plugins!.where((p) => p.enabled).map((p) => p.id).join(',');
    await prefs.setString(_pluginKey, ids);
  }

  static Future<List<String>> getEnabledIds() async {
    if (_plugins == null) return [];
    return _plugins!.where((p) => p.enabled).map((p) => p.id).toList();
  }

  static Future<void> reload() async {
    await loadAll();
  }
}
