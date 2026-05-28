import 'package:flutter/material.dart';

/// Centralized, semantic color palette used across the app.
/// Keep names semantic (role-based) so the design can evolve
/// without changing usages throughout the codebase.
class AppColors {
  AppColors._(); // no instances

  // Primary brand
  static const Color primary = Color(0xFF1F77D2);
  static const Color primaryVariant = Color(0xFF155CA8);
  static const Color onPrimary = Colors.white;

  // Secondary / supportive
  static const Color secondary = Color(0xFF26C281);
  static const Color onSecondary = Colors.white;

  // Accent / destructive
  static const Color accent = Color(0xFFFF6B6B);
  static const Color onAccent = Colors.white;

  // Surface & background
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Colors.white;
  static const Color card = Colors.white;
  static const Color border = Color(0xFFE6E9EE);

  // Text
  static const Color textPrimary = Color(0xFF0F1724); // almost black
  static const Color textSecondary = Color(0xFF6B7280); // muted gray
  static const Color textDisabled = Color(0xFF9CA3AF);

  // Status colors
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF0284C7);

  // Semantic helpers
  static const Color muted = Color(0xFFEDF2F7);
  static const Color overlay = Color(0x66000000); // 40% black
}

/// Helper that returns a light color scheme based on the palette above.
ColorScheme lightColorSchemeFromPalette() {
  return ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    secondary: AppColors.secondary,
    onSecondary: AppColors.onSecondary,
    tertiary: AppColors.accent,
    onTertiary: AppColors.onAccent,
    error: AppColors.error,
    onError: Colors.white,
    background: AppColors.background,
    onBackground: AppColors.textPrimary,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    surfaceVariant: AppColors.muted,
    outline: AppColors.border,
  );
}
