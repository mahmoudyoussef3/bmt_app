import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_theme.dart';

/// The captain app's [ThemeData] — the rider app's theme, unchanged.
///
/// The captain used to derive a theme of its own here: the imported Claude
/// Design slate palette, a Tajawal type scale, and its own input/divider
/// overrides. That whole derivation is commented out at the bottom of this
/// file rather than deleted — every line of it was a design decision, and it
/// is now the only record of what the captain looked like before the two apps
/// were put on one design system.
///
/// From here on `apps/client/core/theme` is the single source of palette, type
/// scale, radii and component styling for both apps. `CaptainColors`,
/// `CaptainTypography` and `CaptainDesignTokens` survive as thin aliases onto
/// it, so the ~1,200 call sites across the captain's widgets keep compiling and
/// simply start rendering in the rider palette.
///
/// This class stays as the captain's entry point for two reasons: `main.dart`
/// and a dozen widget tests already name it, and if the captain ever does need
/// a deviation, one `copyWith` here is the honest place for it — not a second
/// palette file.
class CaptainTheme {
  static ThemeData light() => ClientTheme.light();

  static ThemeData dark() => ClientTheme.dark();
}

// ---------------------------------------------------------------------------
// The captain's former theme, kept for reference. Superseded by ClientTheme.
// ---------------------------------------------------------------------------
//
// static ThemeData light() => _captainise(AppTheme.lightTheme());
//
// static ThemeData dark() => _captainise(AppTheme.darkTheme());
//
// static ThemeData _captainise(ThemeData base) {
//   final isDark = base.brightness == Brightness.dark;
//   final textTheme = CaptainTypography.textThemeFromBrightness(
//     base.brightness,
//   );
//   final canvas = isDark
//       ? CaptainColors.backgroundDark
//       : CaptainColors.backgroundLight;
//   final surface = isDark
//       ? CaptainColors.surfaceDark
//       : CaptainColors.surfaceLight;
//   final border = isDark
//       ? CaptainColors.dividerDark
//       : CaptainColors.dividerLight;
//
//   return base.copyWith(
//     textTheme: textTheme,
//     primaryTextTheme: textTheme,
//     // The design paints every screen on `--bg` and lets the cards be the only
//     // white, so a page that forgets to set its own background still lands on
//     // the canvas rather than on a sheet of white.
//     scaffoldBackgroundColor: canvas,
//     canvasColor: canvas,
//     dividerColor: border,
//     dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
//     inputDecorationTheme: base.inputDecorationTheme.copyWith(
//       filled: true,
//       fillColor: surface,
//       border: OutlineInputBorder(
//         borderRadius: CaptainDesignTokens.br14,
//         borderSide: BorderSide(color: border),
//       ),
//       enabledBorder: OutlineInputBorder(
//         borderRadius: CaptainDesignTokens.br14,
//         borderSide: BorderSide(color: border),
//       ),
//       focusedBorder: const OutlineInputBorder(
//         borderRadius: CaptainDesignTokens.br14,
//         borderSide: BorderSide(color: CaptainColors.primary, width: 1.6),
//       ),
//     ),
//   );
// }
