import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/app_dark_colors.dart';

/// The captain app's palette.
///
/// Light mode is the imported Claude Design token set verbatim — a slate canvas
/// (`--bg`), white cards (`--surface`), a quiet slate fill for anything nested
/// inside a card (`--surface2`), and a hairline `--border` that does the
/// separating so cards do not need a shadow to read as cards.
///
/// Dark mode resolves through [AppDarkColors], the one dark palette the captain
/// and the client share. The design's own dark values are a near match for it
/// and diverging would re-create exactly the per-app drift that file exists to
/// kill — so the ladder below maps onto it rather than restating it.
class CaptainColors {
  static const Color primary = Color(0xFF2563EB);
  static const Color onPrimary = Colors.white;

  static const Color primaryDeep = Color(0xFF4338CA);

  static const Color offline = Color(0xFF64748B);
  static const Color tripActive = primary;

  /// Cancelled, failed, destructive, SOS.
  static const Color error = Color(0xFFEF4444);
  static const Color danger = error;

  /// Needs attention — a late trip, an expiring document, a trip that came up
  /// short. Amber, not blue: the design spends a real hue here so "attention"
  /// cannot be mistaken for "in progress".
  static const Color warning = Color(0xFFD97706);

  /// Done, verified, boarded, on time.
  static const Color success = Color(0xFF16A34A);

  static const Color rating = Color(0xFFFBBF24);

  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Colors.white;

  /// `--surface2`: the fill for a tile nested inside a card, a progress track,
  /// an inactive chip. Never the page and never a card.
  static const Color surfaceAltLight = Color(0xFFF1F5F9);

  static const Color backgroundDark = AppDarkColors.background;
  static const Color surfaceDark = AppDarkColors.surface;
  static const Color surfaceAltDark = AppDarkColors.surfaceRaised;

  static const Color dividerLight = Color(0xFFE2E8F0);
  static const Color dividerDark = AppDarkColors.border;

  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color backgroundFor(BuildContext context) {
    return _isDark(context) ? backgroundDark : backgroundLight;
  }

  static Color surfaceFor(BuildContext context) {
    return _isDark(context) ? surfaceDark : surfaceLight;
  }

  /// The design's `--surface2`.
  static Color surfaceAltFor(BuildContext context) {
    return _isDark(context) ? surfaceAltDark : surfaceAltLight;
  }

  static Color textPrimaryFor(BuildContext context) {
    return _isDark(context) ? AppDarkColors.onSurface : const Color(0xFF0F172A);
  }

  static Color textSecondaryFor(BuildContext context) {
    return _isDark(context)
        ? AppDarkColors.onSurfaceMuted
        : const Color(0xFF64748B);
  }

  static Color dividerFor(BuildContext context) {
    return _isDark(context) ? dividerDark : dividerLight;
  }

  /// The design's `--border`. Same value as [dividerFor]; the name says whether
  /// the line is drawing an edge or splitting two rows.
  static Color borderFor(BuildContext context) => dividerFor(context);

  /// Brand blue **as ink** — a label, an icon, a thin mark.
  ///
  /// [primary] is the fill tone: white on it clears AA, so it stays the same in
  /// both modes for buttons and gradients. That same blue as *text* on a dark
  /// page is under the contrast floor, which is why anything drawn in blue
  /// rather than filled with it reads this instead.
  static Color primaryInkFor(BuildContext context) {
    return _isDark(context) ? AppDarkColors.primaryAccent : primary;
  }

  static Color successFor(BuildContext context) {
    return _isDark(context) ? const Color(0xFF4ADE80) : success;
  }

  static Color warningFor(BuildContext context) {
    return _isDark(context) ? const Color(0xFFFBBF24) : warning;
  }

  static Color dangerFor(BuildContext context) {
    return _isDark(context) ? const Color(0xFFF87171) : error;
  }

  static LinearGradient primaryGradient(BuildContext context) {
    return LinearGradient(
      colors: [Theme.of(context).colorScheme.primary, primaryDeep],
      begin: AlignmentDirectional.topStart,
      end: AlignmentDirectional.bottomEnd,
    );
  }
}
