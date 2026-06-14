import 'package:flutter/material.dart';

class AppTheme {
  // Brand colors — Messenger blue (familiar, trusted)
  static const Color primary = Color(0xFF1877F2);
  static const Color primaryDark = Color(0xFF166FE5);
  static const Color primaryLight = Color(0xFFE7F3FF);
  static const Color accent = Color(0xFFD4A843);
  static const Color accentLight = Color(0xFFE8C872);

  // Light mode
  static const Color backgroundLight = Color(0xFFF0F2F5);
  static const Color surfaceLight = Colors.white;
  static const Color textPrimaryLight = Color(0xFF050505);
  static const Color textSecondaryLight = Color(0xFF65676B);
  static const Color bubbleUserLight = Color(0xFF1877F2);
  static const Color bubbleBotLight = Colors.white;

  // Dark mode
  static const Color backgroundDark = Color(0xFF18191A);
  static const Color surfaceDark = Color(0xFF242526);
  static const Color bubbleUserDark = Color(0xFF1E90FF);
  static const Color bubbleBotDark = Color(0xFF3A3B3C);
  static const Color textPrimaryDark = Color(0xFFE4E6EB);
  static const Color textSecondaryDark = Color(0xFFB0B3B8);

  static const Color success = Color(0xFF2E7D32);
  static const Color error = Color(0xFFE4405F);

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.light(
          primary: primary,
          secondary: accent,
          surface: surfaceLight,
          error: error,
        ),
        scaffoldBackgroundColor: backgroundLight,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: _PauTransitionBuilder(),
            TargetPlatform.iOS: _PauTransitionBuilder(),
          },
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: surfaceLight,
          foregroundColor: textPrimaryLight,
          elevation: 0.5,
          shadowColor: Color(0x10000000),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: surfaceLight,
          indicatorColor: primaryLight,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: primary,
              );
            }
            return const TextStyle(fontSize: 12, color: textSecondaryLight);
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: primary, size: 22);
            }
            return const IconThemeData(color: textSecondaryLight, size: 22);
          }),
        ),
        cardTheme: CardTheme(
          elevation: 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: surfaceLight,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: backgroundLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primary, width: 2),
          ),
          contentPadding: const EdgeInsets.all(16),
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.dark(
          primary: bubbleUserDark,
          secondary: accent,
          surface: surfaceDark,
          error: error,
        ),
        scaffoldBackgroundColor: backgroundDark,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: _PauTransitionBuilder(),
            TargetPlatform.iOS: _PauTransitionBuilder(),
          },
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: surfaceDark,
          foregroundColor: textPrimaryDark,
          elevation: 0.5,
          shadowColor: Color(0x40000000),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: surfaceDark,
          indicatorColor: Color(0x303A3B3C),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: bubbleUserDark,
              );
            }
            return const TextStyle(fontSize: 12, color: textSecondaryDark);
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: bubbleUserDark, size: 22);
            }
            return const IconThemeData(color: textSecondaryDark, size: 22);
          }),
        ),
        cardTheme: CardTheme(
          elevation: 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: surfaceDark,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: bubbleUserDark,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF3A3B3C),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: bubbleUserDark, width: 2),
          ),
          contentPadding: const EdgeInsets.all(16),
        ),
      );
}

/// Custom page transition for consistent smooth navigation.
class _PauTransitionBuilder extends PageTransitionsBuilder {
  const _PauTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const begin = Offset(0.0, 0.06);
    const end = Offset.zero;
    const curve = Curves.easeOutCubic;

    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
    var fadeTween = Tween<double>(begin: 0.0, end: 1.0)
        .chain(CurveTween(curve: curve));

    return SlideTransition(
      position: animation.drive(tween),
      child: FadeTransition(
        opacity: animation.drive(fadeTween),
        child: child,
      ),
    );
  }
}
