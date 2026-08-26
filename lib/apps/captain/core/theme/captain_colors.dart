import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_palette.dart';

/// The captain app's palette — every value now resolved from the rider app's.
///
/// This class no longer *decides* any colour. It is a name-for-name alias onto
/// [ClientColors] so the ~440 captain call sites that already read
/// `CaptainColors.x` keep compiling while rendering the one EWT palette. The
/// captain's former slate/blue values are commented out at the bottom of the
/// file.
///
/// Two conventions carried over from the old file, because the call sites
/// depend on them:
///
/// * **The bare constants are the *fill* tone and do not change with
///   brightness.** [primary] stays the deep brand blue in dark mode too, which
///   is what lets [onPrimary] be a single near-white in both modes — a filled
///   button keeps one checkable contrast ratio instead of two.
/// * **Anything drawn *in* a colour rather than filled with it reads a
///   `…For(context)` accessor**, which resolves light and dark. That is why
///   [primaryInkFor] exists next to [primary]: the same blue as text on the
///   dark page is under the contrast floor.
class CaptainColors {
  /// `--primary`. The fill tone — see the class doc on why it is mode-stable.
  static const Color primary = ClientColors.primary;

  /// `--on-primary`. Text and icons on a [primary] fill.
  static const Color onPrimary = ClientColors.onPrimary;

  /// `--primary-strong`. The pressed / deepest step of the brand ramp.
  static const Color primaryDeep = ClientColors.primaryPressed;

  /// No signal, stale GPS, an inert marker — the rider palette's neutral.
  static const Color offline = ClientColors.journeySlate;

  static const Color tripActive = primary;

  /// Cancelled, failed, destructive, SOS.
  static const Color error = ClientColors.journeyRed;
  static const Color danger = error;

  /// Needs attention — a late trip, an expiring document, a trip that came up
  /// short. Amber, not blue: "attention" must not read as "in progress".
  static const Color warning = ClientColors.journeyAmber;

  /// Done, verified, boarded, on time.
  static const Color success = ClientColors.journeyGreen;

  /// Stars only. The rider palette keeps ratings off the warning ramp on
  /// purpose, so a 4.8-star driver never reads as a caution.
  static const Color rating = ClientColors.rating;

  static const Color backgroundLight = ClientColors.background;
  static const Color surfaceLight = ClientColors.surface;

  /// The fill for a tile nested inside a card, a progress track, an inactive
  /// chip. Never the page and never a card.
  static const Color surfaceAltLight = ClientColors.surfaceMuted;

  static const Color dividerLight = ClientColors.border;

  /// The dark rungs of the same ladder.
  ///
  /// `final`, not `const`: [ClientColors] names the light palette as constants
  /// and reaches dark only through its context accessors, so these read
  /// [ClientPalette] directly. Prefer the `…For(context)` accessors below —
  /// these four exist so the old field names still resolve.
  static final Color backgroundDark = ClientPalette.dark.bg;
  static final Color surfaceDark = ClientPalette.dark.surface;
  static final Color surfaceAltDark = ClientPalette.dark.surface2;
  static final Color dividerDark = ClientPalette.dark.border;

  static Color backgroundFor(BuildContext context) =>
      ClientColors.backgroundFor(context);

  static Color surfaceFor(BuildContext context) =>
      ClientColors.surfaceFor(context);

  /// The rider palette's `--surface-2`.
  static Color surfaceAltFor(BuildContext context) =>
      ClientColors.surfaceMutedFor(context);

  static Color textPrimaryFor(BuildContext context) =>
      ClientColors.textPrimaryFor(context);

  static Color textSecondaryFor(BuildContext context) =>
      ClientColors.textSecondaryFor(context);

  static Color dividerFor(BuildContext context) =>
      ClientColors.borderFor(context);

  /// The rider palette's `--border`. Same value as [dividerFor]; the name says
  /// whether the line is drawing an edge or splitting two rows.
  static Color borderFor(BuildContext context) =>
      ClientColors.borderFor(context);

  /// Brand blue **as ink** — a label, an icon, a thin mark.
  static Color primaryInkFor(BuildContext context) =>
      ClientColors.primaryFor(context);

  static Color successFor(BuildContext context) =>
      ClientColors.journeyGreenFor(context);

  static Color warningFor(BuildContext context) =>
      ClientColors.journeyAmberFor(context);

  static Color dangerFor(BuildContext context) =>
      ClientColors.journeyRedFor(context);

  /// The brand fill on the primary button, the brand mark and the focus card.
  ///
  /// The rider design paints this flat rather than as a blue→teal ramp, so both
  /// stops are the same colour. [context] is ignored and kept only so the five
  /// existing call sites need no edit: this is a *fill*, and per the class doc
  /// a fill is mode-stable so [onPrimary] stays legible on it in dark mode.
  static Gradient primaryGradient(BuildContext context) =>
      ClientColors.primaryGradient;
}

// ---------------------------------------------------------------------------
// The captain's former palette, kept for reference. Superseded by ClientColors.
//
// Light mode was the imported Claude Design token set verbatim — a slate canvas
// (`--bg`), white cards (`--surface`), a quiet slate fill for anything nested
// inside a card (`--surface2`), and a hairline `--border`. Dark mode resolved
// through AppDarkColors, the dark palette the captain and client shared before
// the client moved onto its own two-brightness palette.
// ---------------------------------------------------------------------------
//
// static const Color primary = Color(0xFF2563EB);
// static const Color onPrimary = Colors.white;
// static const Color primaryDeep = Color(0xFF4338CA);
//
// static const Color offline = Color(0xFF64748B);
// static const Color tripActive = primary;
//
// static const Color error = Color(0xFFEF4444);
// static const Color danger = error;
// static const Color warning = Color(0xFFD97706);
// static const Color success = Color(0xFF16A34A);
// static const Color rating = Color(0xFFFBBF24);
//
// static const Color backgroundLight = Color(0xFFF8FAFC);
// static const Color surfaceLight = Colors.white;
// static const Color surfaceAltLight = Color(0xFFF1F5F9);
//
// static const Color backgroundDark = AppDarkColors.background;
// static const Color surfaceDark = AppDarkColors.surface;
// static const Color surfaceAltDark = AppDarkColors.surfaceRaised;
//
// static const Color dividerLight = Color(0xFFE2E8F0);
// static const Color dividerDark = AppDarkColors.border;
//
// static bool _isDark(BuildContext context) =>
//     Theme.of(context).brightness == Brightness.dark;
//
// static Color backgroundFor(BuildContext context) =>
//     _isDark(context) ? backgroundDark : backgroundLight;
//
// static Color surfaceFor(BuildContext context) =>
//     _isDark(context) ? surfaceDark : surfaceLight;
//
// static Color surfaceAltFor(BuildContext context) =>
//     _isDark(context) ? surfaceAltDark : surfaceAltLight;
//
// static Color textPrimaryFor(BuildContext context) =>
//     _isDark(context) ? AppDarkColors.onSurface : const Color(0xFF0F172A);
//
// static Color textSecondaryFor(BuildContext context) => _isDark(context)
//     ? AppDarkColors.onSurfaceMuted
//     : const Color(0xFF64748B);
//
// static Color dividerFor(BuildContext context) =>
//     _isDark(context) ? dividerDark : dividerLight;
//
// static Color borderFor(BuildContext context) => dividerFor(context);
//
// static Color primaryInkFor(BuildContext context) =>
//     _isDark(context) ? AppDarkColors.primaryAccent : primary;
//
// static Color successFor(BuildContext context) =>
//     _isDark(context) ? const Color(0xFF4ADE80) : success;
//
// static Color warningFor(BuildContext context) =>
//     _isDark(context) ? const Color(0xFFFBBF24) : warning;
//
// static Color dangerFor(BuildContext context) =>
//     _isDark(context) ? const Color(0xFFF87171) : error;
//
// static LinearGradient primaryGradient(BuildContext context) {
//   return LinearGradient(
//     colors: [Theme.of(context).colorScheme.primary, primaryDeep],
//     begin: AlignmentDirectional.topStart,
//     end: AlignmentDirectional.bottomEnd,
//   );
// }
