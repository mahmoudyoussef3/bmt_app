import 'dart:math' as math;

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
///
/// **The captain renders that ramp one step smaller.** The rider app is a
/// storefront — big headings, generous body — while the captain is a working
/// tool: dense trip rows, seat grids, manifests and status stacks, read a
/// glance at a time. At the rider sizes those screens spend their height on
/// type instead of content. So every size here passes through [compact]
/// before it is handed out, and `CaptainTheme` runs the ambient [TextTheme]
/// through [compactTextTheme] so the app bar, buttons, chips, tabs, inputs
/// and dialogs shrink by the same rule rather than staying behind.
///
/// This is the captain's one deliberate deviation from the shared design
/// system: the ramp's *proportions*, weights, tracking and typeface are still
/// the rider's — only the absolute sizes differ, by a single factor. To retune
/// the whole app, change [scale]; nothing else.
class CaptainTypography {
  /// How much of the rider size the captain renders. One knob for the app.
  ///
  /// 0.88 is a step, not a jump: a 24px heading lands on 21, 16px body on 14.
  /// Anything much below this and the Arabic diacritics on a sunlit phone
  /// stop resolving — this is a screen read from a driver's seat.
  static const double scale = 0.88;

  /// The size no text drops under, whatever [scale] says.
  ///
  /// The ramp's smallest steps (11px labels, 12px captions) are already at the
  /// edge of legible; scaling them further would buy a pixel and cost a
  /// reading. So compaction takes the top of the ramp down and leaves the
  /// bottom alone, which also widens the contrast between the two.
  static const double minFontSize = 10;

  /// The captain's size for a rider size — [scale], floored at
  /// [minFontSize] and snapped to a half pixel so the ramp stays a ramp.
  static double sizeOf(double riderSize) =>
      math.max(minFontSize, (riderSize * scale * 2).roundToDouble() / 2);

  /// [style] at the captain's size. A style with no explicit size inherits
  /// one, so it is returned untouched rather than pinned here.
  static TextStyle compact(TextStyle style) {
    final size = style.fontSize;
    if (size == null) return style;
    return style.copyWith(fontSize: sizeOf(size));
  }

  /// [compact] across a whole [TextTheme] — what `CaptainTheme` feeds the
  /// theme so Material's own components size themselves off the captain ramp.
  static TextTheme compactTextTheme(TextTheme theme) => TextTheme(
    displayLarge: _at(theme.displayLarge),
    displayMedium: _at(theme.displayMedium),
    displaySmall: _at(theme.displaySmall),
    headlineLarge: _at(theme.headlineLarge),
    headlineMedium: _at(theme.headlineMedium),
    headlineSmall: _at(theme.headlineSmall),
    titleLarge: _at(theme.titleLarge),
    titleMedium: _at(theme.titleMedium),
    titleSmall: _at(theme.titleSmall),
    bodyLarge: _at(theme.bodyLarge),
    bodyMedium: _at(theme.bodyMedium),
    bodySmall: _at(theme.bodySmall),
    labelLarge: _at(theme.labelLarge),
    labelMedium: _at(theme.labelMedium),
    labelSmall: _at(theme.labelSmall),
  );

  static TextStyle? _at(TextStyle? style) =>
      style == null ? null : compact(style);

  static final Map<bool, TextTheme> _cache = {};

  /// The scale the captain currently renders — whatever `CaptainTheme` put on
  /// the ambient [ThemeData], already compacted, so a widget reading this
  /// cannot drift from the app bar and dialogs beside it.
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
      () => compactTextTheme(
        (isDark ? ClientTheme.dark() : ClientTheme.light()).textTheme,
      ),
    );
  }

  static TextStyle displayLarge(BuildContext context) =>
      compact(ClientTypography.displayLarge(context));

  static TextStyle displayMedium(BuildContext context) =>
      compact(ClientTypography.displayMedium(context));

  /// Collapses onto [displayMedium] — the rider ramp's second display step is
  /// the captain's old 32, so this is an exact match rather than a rounding.
  static TextStyle displaySmall(BuildContext context) =>
      compact(ClientTypography.displayMedium(context));

  /// Collapses onto [headlineMedium]: the rider ramp draws one 24px heading
  /// where the captain drew 28 and 24.
  static TextStyle headlineLarge(BuildContext context) =>
      compact(ClientTypography.headingLarge(context));

  static TextStyle headlineMedium(BuildContext context) =>
      compact(ClientTypography.headingLarge(context));

  /// Collapses onto [headlineMedium] for the same reason — the captain's 22
  /// sat between the rider ramp's 24 and 20 and rounds up to the heading.
  static TextStyle headlineSmall(BuildContext context) =>
      compact(ClientTypography.headingLarge(context));

  static TextStyle titleLarge(BuildContext context) =>
      compact(ClientTypography.headingMedium(context));

  static TextStyle titleMedium(BuildContext context) =>
      compact(ClientTypography.headingMedium(context));

  static TextStyle titleSmall(BuildContext context) =>
      compact(ClientTypography.headingSmall(context));

  static TextStyle bodyLarge(BuildContext context) =>
      compact(ClientTypography.bodyLarge(context));

  static TextStyle bodyMedium(BuildContext context) =>
      compact(ClientTypography.bodyMedium(context));

  static TextStyle bodySmall(BuildContext context) =>
      compact(ClientTypography.bodySmall(context));

  static TextStyle labelLarge(BuildContext context) =>
      compact(ClientTypography.labelLarge(context));

  static TextStyle labelMedium(BuildContext context) =>
      compact(ClientTypography.labelMedium(context));

  static TextStyle labelSmall(BuildContext context) =>
      compact(ClientTypography.labelSmall(context));
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
