import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/app_theme.dart';

import 'captain_typography.dart';

class CaptainTheme {
  static ThemeData light() => _withCairoText(AppTheme.lightTheme());

  static ThemeData dark() => _withCairoText(AppTheme.darkTheme());

  static ThemeData _withCairoText(ThemeData base) {
    final textTheme = CaptainTypography.textThemeFromBrightness(
      base.brightness,
    );
    return base.copyWith(textTheme: textTheme, primaryTextTheme: textTheme);
  }
}
