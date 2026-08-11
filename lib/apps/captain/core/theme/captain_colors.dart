import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/app_dark_colors.dart';

class CaptainColors {
  static const Color primary = Color(0xFF2563EB);
  static const Color onPrimary = Colors.white;

  static const Color primaryDeep = Color(0xFF4338CA);

  static const Color offline = Color(0xFF64748B);
  static const Color tripActive = primary;
  static const Color error = Color(0xFFEF4444);
  static const Color warning = primary;
  static const Color success = primary;

  static const Color rating = Color(0xFFFBBF24);

  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Colors.white;
  static const Color backgroundDark = AppDarkColors.background;
  static const Color surfaceDark = AppDarkColors.surface;

  static const Color dividerLight = Color(0xFFE2E8F0);
  static const Color dividerDark = AppDarkColors.border;

  static Color backgroundFor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? backgroundDark
        : backgroundLight;
  }

  static Color surfaceFor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? surfaceDark
        : surfaceLight;
  }

  static Color textPrimaryFor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppDarkColors.onSurface
        : const Color(0xFF0F172A);
  }

  static Color textSecondaryFor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppDarkColors.onSurfaceMuted
        : const Color(0xFF64748B);
  }

  static Color dividerFor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? dividerDark
        : dividerLight;
  }

  static LinearGradient primaryGradient(BuildContext context) {
    return LinearGradient(
      colors: [Theme.of(context).colorScheme.primary, primaryDeep],
      begin: AlignmentDirectional.topStart,
      end: AlignmentDirectional.bottomEnd,
    );
  }
}
