import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'config/globals.dart';
import 'services/book_registry.dart';
import 'services/plugin_registry.dart';
import 'services/hive_storage.dart';
import 'services/bible_loader.dart';
import 'services/lyrics_loader.dart';
import 'app.dart';
import 'screens/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ));
  } catch (e) {
    debugPrint('System UI config failed (non-fatal): $e');
  }

  // Load saved theme
  try {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('app_theme') ?? 'system';
    themeNotifier.value = saved == 'light'
        ? ThemeMode.light
        : saved == 'dark' ? ThemeMode.dark : ThemeMode.system;
  } catch (e) {
    debugPrint('Failed to load theme preference: $e');
  }

  // Load books
  try {
    await BookRegistry.loadAll();
  } catch (e) {
    debugPrint('Failed to load books: $e');
  }

  // Load plugins from JSON config
  try {
    await PluginRegistry.loadAll();
  } catch (e) {
    debugPrint('Failed to load plugins: $e');
  }

  // Load lyrics from .md files
  try {
    await LyricsLoader.loadAll();
  } catch (e) {
    debugPrint('Lyrics load failed: $e');
  }

  // Load the full Tedim Bible (30,715 verses)
  try {
    await BibleLoader.load();
  } catch (e) {
    debugPrint('Bible load failed: $e');
  }

  // Initialize Hive for structured local storage
  await HiveStorage.initialize();
  await HiveStorage.migrateFromSharedPreferences();

  // Start connectivity monitoring
  connectivityService.startMonitoring();

  runApp(const PauApp());
}

class PauApp extends StatefulWidget {
  const PauApp({super.key});

  @override
  State<PauApp> createState() => _PauAppState();
}

class _PauAppState extends State<PauApp> {
  bool? _onboardingComplete;

  @override
  void initState() {
    super.initState();
    themeNotifier.addListener(() => setState(() {}));
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final complete = prefs.getBool('onboarding_complete') ?? false;
    if (mounted) setState(() => _onboardingComplete = complete);
  }

  @override
  Widget build(BuildContext context) {
    if (_onboardingComplete == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeNotifier.value,
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      title: 'Pau',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeNotifier.value,
      home: _onboardingComplete!
          ? const AppShell()
          : const OnboardingScreen(),
    );
  }
}
