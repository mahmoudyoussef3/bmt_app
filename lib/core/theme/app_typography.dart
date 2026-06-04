import 'package:flutter/material.dart';

import 'text_themes.dart';

/// Semantic typography roles for consistent hierarchy app-wide.
class AppTypography {
  AppTypography._();

  static TextStyle display(ColorScheme scheme) =>
      AppTextThemes.headlineStrong(scheme);

  static TextStyle heading(ColorScheme scheme) =>
      (AppTextThemes.subtitle(scheme)).copyWith(fontWeight: FontWeight.w700);

  static TextStyle subheading(ColorScheme scheme) => AppTextThemes.textThemeFor(
    scheme,
  ).bodyMedium!.copyWith(fontWeight: FontWeight.w600);

  static TextStyle body(ColorScheme scheme) =>
      AppTextThemes.textThemeFor(scheme).bodyLarge!;

  static TextStyle caption(ColorScheme scheme) => AppTextThemes.caption(scheme);
}
