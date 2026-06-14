import 'package:flutter/material.dart';

/// Wraps a widget to dismiss the keyboard on tap outside text fields.
/// Apply as the body of every Scaffold for consistent keyboard UX.
class KeyboardDismiss extends StatelessWidget {
  final Widget child;

  const KeyboardDismiss({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: child,
    );
  }
}

/// Remix: puts everything inside a GestureDetector that dismisses keyboard on tap.
extension KeyboardDismissExtension on Widget {
  Widget get dismissKeyboard => KeyboardDismiss(child: this);
}
