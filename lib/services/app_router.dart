import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app.dart';
import '../screens/privacy_screen.dart';
import '../screens/onboarding_screen.dart';

/// Central router configuration for Pau.
/// Enables deep linking, named routes, and future route guards.
class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const AppShell(),
      ),
      GoRoute(
        path: '/privacy',
        name: 'privacy',
        builder: (context, state) => const PrivacyScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
    ],
  );

  /// Navigate to a path using the root navigator
  static void go(BuildContext context, String path) {
    context.go(path);
  }

  /// Pop back
  static void pop(BuildContext context) {
    if (context.canPop()) context.pop();
  }
}
