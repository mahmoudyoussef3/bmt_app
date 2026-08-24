import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shared premium typography for the BMT system.
class AppTextThemes {
  AppTextThemes._();

  static const double _scale = 1.0;
  static const FontWeight _b = FontWeight.w800;
  static const FontWeight _sb = FontWeight.w700;
  static const FontWeight _m = FontWeight.w500;
  static const FontWeight _r = FontWeight.w400;

  static TextTheme textThemeFor(ColorScheme colorScheme) {
    final onSurface = colorScheme.onSurface;

    final baseTextTheme =
        TextTheme(
          displayLarge: TextStyle(
            fontSize: 30 * _scale,
            fontWeight: _b,
            height: 1.12,
            letterSpacing: -0.5,
          ),
          displayMedium: TextStyle(
            fontSize: 24 * _scale,
            fontWeight: _b,
            height: 1.16,
            letterSpacing: -0.2,
          ),
          displaySmall: TextStyle(
            fontSize: 20 * _scale,
            fontWeight: _sb,
            height: 1.22,
            letterSpacing: -0.1,
          ),
          headlineSmall: TextStyle(
            fontSize: 18 * _scale,
            fontWeight: _sb,
            height: 1.26,
          ),
          bodyLarge: TextStyle(
            fontSize: 16 * _scale,
            fontWeight: _r,
            height: 1.58,
          ),
          bodyMedium: TextStyle(
            fontSize: 14 * _scale,
            fontWeight: _m,
            height: 1.5,
            letterSpacing: 0.1,
          ),
          bodySmall: TextStyle(
            fontSize: 13 * _scale,
            fontWeight: _r,
            height: 1.42,
            letterSpacing: 0.1,
          ),
          labelLarge: TextStyle(
            fontSize: 14 * _scale,
            fontWeight: _sb,
            height: 1.3,
            letterSpacing: 0.2,
          ),
          labelMedium: TextStyle(
            fontSize: 12 * _scale,
            fontWeight: _sb,
            height: 1.25,
            letterSpacing: 0.35,
          ),
          labelSmall: TextStyle(
            fontSize: 11 * _scale,
            fontWeight: _m,
            height: 1.2,
            letterSpacing: 0.35,
          ),
          titleLarge: TextStyle(
            fontSize: 18 * _scale,
            fontWeight: _sb,
            height: 1.28,
          ),
          titleMedium: TextStyle(
            fontSize: 16 * _scale,
            fontWeight: _sb,
            height: 1.3,
          ),
          titleSmall: TextStyle(
            fontSize: 14 * _scale,
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

  /// [textThemeFor]'s exact scale, set in Cairo instead of Outfit.
  ///
  /// Outfit carries no Arabic glyphs, so an Arabic string styled with it falls
  /// through to whatever face the platform happens to pick — which is why an
  /// Arabic screen never matches its Latin counterpart, or itself across
  /// devices. Cairo covers both scripts and is already the face the captain
  /// and dashboard apps render.
  ///
  /// Only the family changes: sizes, weights, heights, tracking and colours
  /// all come from [textThemeFor].
  static TextTheme cairoTextThemeFor(ColorScheme colorScheme) =>
      GoogleFonts.cairoTextTheme(textThemeFor(colorScheme));

  static TextStyle headlineStrong(ColorScheme cs) =>
      textThemeFor(cs).displayLarge!;
  static TextStyle subtitle(ColorScheme cs) => textThemeFor(cs).displaySmall!;
  static TextStyle caption(ColorScheme cs) => textThemeFor(cs).titleMedium!;

  static TextStyle badgeText(ColorScheme cs) => GoogleFonts.outfit(
    fontSize: 11 * _scale,
    fontWeight: _sb,
    height: 1.2,
    letterSpacing: 0.35,
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
    height: 1.3,
    color: cs.onSurface,
  );
}
