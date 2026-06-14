import 'package:flutter/material.dart';

/// Plugin data model — no hardcoded data, all loaded from JSON via PluginRegistry.
class PauPlugin {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final String type; // 'online', 'offline', 'both'
  bool enabled;

  PauPlugin({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.color = Colors.blue,
    this.type = 'online',
    this.enabled = false,
  });
}
