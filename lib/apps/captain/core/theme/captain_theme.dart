import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/app_theme.dart';

import 'captain_colors.dart';
import 'captain_design_tokens.dart';
import 'captain_typography.dart';

class CaptainTheme {
  static ThemeData light() => _captainise(AppTheme.lightTheme());

  static ThemeData dark() => _captainise(AppTheme.darkTheme());

  static ThemeData _captainise(ThemeData base) {
    final isDark = base.brightness == Brightness.dark;
    final textTheme = CaptainTypography.textThemeFromBrightness(
      base.brightness,
    );
    final canvas = isDark
        ? CaptainColors.backgroundDark
        : CaptainColors.backgroundLight;
    final surface = isDark
        ? CaptainColors.surfaceDark
        : CaptainColors.surfaceLight;
    final border = isDark
        ? CaptainColors.dividerDark
        : CaptainColors.dividerLight;

    return base.copyWith(
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      // The design paints every screen on `--bg` and lets the cards be the only
      // white, so a page that forgets to set its own background still lands on
      // the canvas rather than on a sheet of white.
      scaffoldBackgroundColor: canvas,
      canvasColor: canvas,
      dividerColor: border,
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: CaptainDesignTokens.br14,
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: CaptainDesignTokens.br14,
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: CaptainDesignTokens.br14,
          borderSide: BorderSide(color: CaptainColors.primary, width: 1.6),
        ),
      ),
    );
  }
}
