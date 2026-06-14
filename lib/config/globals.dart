import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';

/// Shared app-wide singletons — avoids circular imports between main.dart and screens.
final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);
final connectivityService = ConnectivityService();
