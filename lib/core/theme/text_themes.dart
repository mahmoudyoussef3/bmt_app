import 'package:flutter/material.dart';

/// AppTextThemes implements the typographic system described in
/// docs/FLUTTER_TEXT_STYLES.dart and DESIGN_SYSTEM_OVERVIEW.md.
class AppTextThemes {
  AppTextThemes._();

  static const String primaryFont = 'Geist';
  static const String monoFont = 'GeistMono';

  static TextTheme lightTextTheme(ColorScheme colorScheme) {
    final primary = colorScheme.onSurface;

    return TextTheme(
      displayLarge: const TextStyle(
        fontFamily: primaryFont,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.4,
      ), // H1
      displayMedium: const TextStyle(
        fontFamily: primaryFont,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.4,
      ), // H2
      displaySmall: const TextStyle(
        fontFamily: primaryFont,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.4,
      ), // H3

      headlineLarge: const TextStyle(
        fontFamily: primaryFont,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.45,
      ),
      headlineMedium: const TextStyle(
        fontFamily: primaryFont,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.45,
      ),

      titleLarge: const TextStyle(
        fontFamily: primaryFont,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
      titleMedium: const TextStyle(
        fontFamily: primaryFont,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      titleSmall: const TextStyle(
        fontFamily: primaryFont,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.3,
      ),

      bodyLarge: const TextStyle(
        fontFamily: primaryFont,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      bodyMedium: const TextStyle(
        fontFamily: primaryFont,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.45,
      ),
      bodySmall: const TextStyle(
        fontFamily: primaryFont,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.3,
      ),

      labelLarge: const TextStyle(
        fontFamily: primaryFont,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: const TextStyle(
        fontFamily: primaryFont,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),

      // Buttons / Badge / Numeric
      // Use `copyWith` at call sites for color changes
      // Numeric styles use a monospace font family
      // Price / Numeric Large
      // Note: not all named fields are used; these are base styles.
    ).apply(
      bodyColor: primary,
      displayColor: primary,
      decorationColor: primary,
    );
  }
}
