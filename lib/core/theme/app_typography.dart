import 'package:flutter/material.dart';

import 'text_themes.dart';

class AppTypography {
  AppTypography._();

  static TextStyle display(ColorScheme scheme) =>
      AppTextThemes.headlineStrong(scheme);

  static TextStyle heading1(ColorScheme scheme) =>
      AppTextThemes.headlineStrong(scheme).copyWith(
        fontWeight: FontWeight.w800,
      );

  static TextStyle heading2(ColorScheme scheme) =>
      AppTextThemes.subtitle(scheme).copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 22,
      );

  static TextStyle heading3(ColorScheme scheme) =>
      AppTextThemes.subtitle(scheme).copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 18,
      );

  static TextStyle heading(ColorScheme scheme) =>
      heading2(scheme);

  static TextStyle subheading(ColorScheme scheme) =>
      AppTextThemes.textThemeFor(
        scheme,
      ).bodyMedium!.copyWith(
        fontWeight: FontWeight.w600,
      );

  static TextStyle body(ColorScheme scheme) =>
      AppTextThemes.textThemeFor(
        scheme,
      ).bodyLarge!;

  static TextStyle bodyMedium(ColorScheme scheme) =>
      AppTextThemes.textThemeFor(
        scheme,
      ).bodyMedium!;

  static TextStyle bodySmall(ColorScheme scheme) =>
      AppTextThemes.textThemeFor(
        scheme,
      ).bodySmall!;

  static TextStyle caption(ColorScheme scheme) =>
      AppTextThemes.caption(scheme);

  static TextStyle button(ColorScheme scheme) =>
      AppTextThemes.textThemeFor(
        scheme,
      ).labelLarge!.copyWith(
        fontWeight: FontWeight.w600,
      );
}