import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/app_theme.dart';

import 'captain_typography.dart';

class CaptainTheme {
  // The shared AppTheme's text theme is Latin-only (Google Fonts "Outfit"),
  // which has no Arabic glyphs. Every captain screen is Arabic, so any widget
  // reading the ambient Theme.of(context).textTheme instead of
  // CaptainTypography directly (e.g. shared CaptainCard/CaptainEmptyState)
  // would silently fall back to each OS's own Arabic system font — a visible
  // iOS-vs-Android mismatch. Overriding the theme's textTheme with Cairo here
  // makes that fallback correct everywhere, not just where someone remembered
  // to opt in.
  static ThemeData light() => _withCairoText(AppTheme.lightTheme());

  static ThemeData dark() => _withCairoText(AppTheme.darkTheme());

  static ThemeData _withCairoText(ThemeData base) {
    final textTheme = CaptainTypography.textThemeFromBrightness(
      base.brightness,
    );
    return base.copyWith(textTheme: textTheme, primaryTextTheme: textTheme);
  }
}
