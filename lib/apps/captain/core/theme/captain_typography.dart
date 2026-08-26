import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_theme.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// The captain app's type scale — the rider app's, under the captain's names.
///
/// The captain used to build its own Tajawal scale (48/36/32/28/24/22/20/18/16
/// …, titles at w800); that block is commented out at the bottom of the file.
/// Both apps now render the one shared scale in Cairo, defined by
/// [ClientTypography] and set on [ThemeData] by `ClientTheme`.
///
/// The rider ramp has fewer steps than the captain's did — deliberately: it
/// draws two display sizes, three heading sizes, three body sizes and three
/// label sizes and nothing in between. So three captain names collapse onto a
/// neighbour ([displaySmall], [headlineLarge] and [headlineSmall]), which is
/// the point of the unification rather than a gap in it. The accessors are all
/// kept so no captain widget has to be touched.
class CaptainTypography {
  static final Map<bool, TextTheme> _cache = {};

  /// The scale the captain currently renders — whatever `ClientTheme` put on
  /// the ambient [ThemeData], so a widget reading this cannot drift from the
  /// app bar and dialogs beside it.
  static TextTheme textTheme(BuildContext context) =>
      Theme.of(context).textTheme;

  /// The same scale resolved without a context.
  ///
  /// Only the captain's old `_captainise` needed this. Kept — and cached,
  /// because building a [ThemeData] is not free — for anything that has a
  /// [Brightness] but no element yet.
  static TextTheme textThemeFromBrightness(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return _cache.putIfAbsent(
      isDark,
      () => (isDark ? ClientTheme.dark() : ClientTheme.light()).textTheme,
    );
  }

  static TextStyle displayLarge(BuildContext context) =>
      ClientTypography.displayLarge(context);

  static TextStyle displayMedium(BuildContext context) =>
      ClientTypography.displayMedium(context);

  /// Collapses onto [displayMedium] — the rider ramp's second display step is
  /// the captain's old 32, so this is an exact match rather than a rounding.
  static TextStyle displaySmall(BuildContext context) =>
      ClientTypography.displayMedium(context);

  /// Collapses onto [headlineMedium]: the rider ramp draws one 24px heading
  /// where the captain drew 28 and 24.
  static TextStyle headlineLarge(BuildContext context) =>
      ClientTypography.headingLarge(context);

  static TextStyle headlineMedium(BuildContext context) =>
      ClientTypography.headingLarge(context);

  /// Collapses onto [headlineMedium] for the same reason — the captain's 22
  /// sat between the rider ramp's 24 and 20 and rounds up to the heading.
  static TextStyle headlineSmall(BuildContext context) =>
      ClientTypography.headingLarge(context);

  static TextStyle titleLarge(BuildContext context) =>
      ClientTypography.headingMedium(context);

  static TextStyle titleMedium(BuildContext context) =>
      ClientTypography.headingMedium(context);

  static TextStyle titleSmall(BuildContext context) =>
      ClientTypography.headingSmall(context);

  static TextStyle bodyLarge(BuildContext context) =>
      ClientTypography.bodyLarge(context);

  static TextStyle bodyMedium(BuildContext context) =>
      ClientTypography.bodyMedium(context);

  static TextStyle bodySmall(BuildContext context) =>
      ClientTypography.bodySmall(context);

  static TextStyle labelLarge(BuildContext context) =>
      ClientTypography.labelLarge(context);

  static TextStyle labelMedium(BuildContext context) =>
      ClientTypography.labelMedium(context);

  static TextStyle labelSmall(BuildContext context) =>
      ClientTypography.labelSmall(context);
}

// ---------------------------------------------------------------------------
// The captain's former type scale, kept for reference.
// Superseded by ClientTypography.
//
// Tajawal was the imported design's typeface: it carries a real 800/900 and its
// Arabic counters stay open at the 11–13px the dense rows on these screens run
// at. Titles sat at w800 rather than w700 to match — that design leaned on
// weight, not size, to rank a card's heading against its body.
// ---------------------------------------------------------------------------
//
// static final Map<bool, TextTheme> _cache = {};
//
// static TextTheme textTheme(BuildContext context) {
//   final isDark = Theme.of(context).brightness == Brightness.dark;
//   return _themeFor(isDark);
// }
//
// static TextTheme textThemeFromBrightness(Brightness brightness) =>
//     _themeFor(brightness == Brightness.dark);
//
// static TextTheme _themeFor(bool isDark) =>
//     _cache.putIfAbsent(isDark, () => _buildTheme(isDark));
//
// static TextTheme _buildTheme(bool isDark) {
//   final color = isDark ? Colors.white : const Color(0xFF0F172A);
//   final mutedColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
//
//   final base = GoogleFonts.tajawalTextTheme().apply(
//     bodyColor: color,
//     displayColor: color,
//   );
//
//   return base.copyWith(
//     displayLarge:  … fontSize: 48, fontWeight: w900, letterSpacing: -1, height: 1.1,
//     displayMedium: … fontSize: 36, fontWeight: w800, letterSpacing: -0.5, height: 1.2,
//     displaySmall:  … fontSize: 32, fontWeight: w800, height: 1.2,
//     headlineLarge: … fontSize: 28, fontWeight: w800, height: 1.3,
//     headlineMedium:… fontSize: 24, fontWeight: w800, height: 1.3,
//     headlineSmall: … fontSize: 22, fontWeight: w800, height: 1.3,
//     titleLarge:    … fontSize: 20, fontWeight: w800, height: 1.4,
//     titleMedium:   … fontSize: 18, fontWeight: w800, height: 1.4,
//     titleSmall:    … fontSize: 16, fontWeight: w800, height: 1.4,
//     bodyLarge:     … fontSize: 16, fontWeight: w600, height: 1.5,
//     bodyMedium:    … fontSize: 14, fontWeight: w600, height: 1.5,
//     bodySmall:     … fontSize: 13, fontWeight: w600, height: 1.5,
//     labelLarge:    … fontSize: 14, fontWeight: w700, color: mutedColor,
//     labelMedium:   … fontSize: 12, fontWeight: w700, color: mutedColor,
//     labelSmall:    … fontSize: 11, fontWeight: w700, color: mutedColor,
//                                                     letterSpacing: 0.5,
//   );
// }
