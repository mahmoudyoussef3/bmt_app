import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AppTextThemes implements the typographic system described in
/// docs/FLUTTER_TEXT_STYLES.dart and DESIGN_SYSTEM_OVERVIEW.md.
class AppTextThemes {
  AppTextThemes._();

  // Centralized scale and weights for consistent typography across the app.
  static const double _scale = 1.0; // keep multiplier for easy tuning
  static const FontWeight _b = FontWeight.w700;
  static const FontWeight _sb = FontWeight.w600;
  static const FontWeight _m = FontWeight.w500;
  static const FontWeight _r = FontWeight.w400;

  static TextTheme textThemeFor(ColorScheme colorScheme) {
    final onSurface = colorScheme.onSurface;

    final baseTextTheme =
        TextTheme(
          // Page / Section titles
          displayLarge: TextStyle(
            fontSize: 28 * _scale,
            fontWeight: _b,
            height: 1.2,
            letterSpacing: -0.4,
          ), // H1
          displayMedium: TextStyle(
            fontSize: 22 * _scale,
            fontWeight: _sb,
            height: 1.25,
          ), // H2
          displaySmall: TextStyle(
            fontSize: 18 * _scale,
            fontWeight: _sb,
            height: 1.3,
          ), // H3 / Card titles
          // Body
          bodyLarge: TextStyle(
            fontSize: 16 * _scale,
            fontWeight: _r,
            height: 1.6,
          ), // comfortable reading
          bodyMedium: TextStyle(
            fontSize: 14 * _scale,
            fontWeight: _m,
            height: 1.5,
            letterSpacing: 0.2,
          ),
          bodySmall: TextStyle(
            fontSize: 13 * _scale,
            fontWeight: _r,
            height: 1.45,
            letterSpacing: 0.2,
          ),

          // Labels / badges
          labelLarge: TextStyle(
            fontSize: 13 * _scale,
            fontWeight: _m,
            height: 1.4,
            letterSpacing: 0.4,
          ),
          labelSmall: TextStyle(
            fontSize: 12 * _scale,
            fontWeight: _r,
            height: 1.4,
            letterSpacing: 0.4,
          ),

          // Buttons / action labels
          titleLarge: TextStyle(
            fontSize: 16 * _scale,
            fontWeight: _sb,
            height: 1.3,
          ),

          // Captions / small helper text
          titleMedium: TextStyle(
            fontSize: 12 * _scale,
            fontWeight: _r,
            height: 1.4,
          ),
          titleSmall: TextStyle(
            fontSize: 11 * _scale,
            fontWeight: _m,
            height: 1.3,
          ),
        ).apply(
          bodyColor: onSurface,
          displayColor: onSurface,
          decorationColor: onSurface,
        );

    return GoogleFonts.outfitTextTheme(baseTextTheme);
  }

  // Semantic helpers for common patterns
  static TextStyle headlineStrong(ColorScheme cs) =>
      textThemeFor(cs).displayLarge!;
  static TextStyle subtitle(ColorScheme cs) => textThemeFor(cs).displaySmall!;
  static TextStyle caption(ColorScheme cs) => textThemeFor(cs).titleMedium!;

  static TextStyle badgeText(ColorScheme cs) => GoogleFonts.outfit(
    fontSize: 11 * _scale,
    fontWeight: _m,
    height: 1.4,
    letterSpacing: 0.4,
    color: cs.onSurface,
  );

  static TextStyle priceEmphasis(ColorScheme cs) => GoogleFonts.firaCode(
    fontSize: 18 * _scale,
    fontWeight: _b,
    height: 1.2,
    color: cs.onSurface,
  );

  static TextStyle smallNumeric(ColorScheme cs) => GoogleFonts.firaCode(
    fontSize: 14 * _scale,
    fontWeight: _m,
    height: 1.4,
    color: cs.onSurface,
  );
}
