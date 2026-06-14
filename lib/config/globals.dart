import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';

/// Shared app-wide singletons — avoids circular imports between main.dart and screens.
final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);
final connectivityService = ConnectivityService();

/// Navigation — lets home screen switch to translate tab with language presets.
class TabRequest {
  final int index;
  final String? sourceLang;
  final String? targetLang;
  const TabRequest(this.index, {this.sourceLang, this.targetLang});
}
final tabNotifier = ValueNotifier<TabRequest?>(null);
