import 'package:flutter/widgets.dart';

/// Single source of truth for whether animations should be suppressed.
///
/// Mirrors the OS-level "reduce motion" / "disable animations" accessibility
/// preference so every animated widget checks it the same way instead of
/// re-inlining the platform lookup.
abstract final class AppMotion {
  const AppMotion._();

  static bool get reduceMotion => WidgetsBinding
      .instance
      .platformDispatcher
      .accessibilityFeatures
      .disableAnimations;
}
