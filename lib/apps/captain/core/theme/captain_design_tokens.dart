import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';

/// The captain app's spacing, radii and elevation — aliases onto the rider
/// app's tokens.
///
/// Nothing here holds a number of its own any more except the two spacing steps
/// the rider scale does not name. The captain's former values are commented out
/// at the bottom of the file.
///
/// The radii are where the unification actually shows: the rider design draws
/// three shapes and no more — fields and small rows at 12, buttons and inner
/// panels at 14–16, cards at 20 — so the captain's 24 and 32 fold onto the card
/// and hero steps. The `r24`/`r32` names stay because ~13 call sites use them.
class CaptainDesignTokens {
  CaptainDesignTokens._();

  static const double s4 = ClientSpacing.xxs;
  static const double s8 = ClientSpacing.xs;
  static const double s12 = ClientSpacing.sm;
  static const double s16 = ClientSpacing.md;

  /// 20 and 40 are the two steps the rider scale skips (it goes 16 → 24 → 32 →
  /// 48). Left as literals rather than rounded onto a neighbour: they carry ~50
  /// captain layouts between them, and nudging every one of those by 4px is a
  /// layout change, not a theme change.
  static const double s20 = 20.0;

  static const double s24 = ClientSpacing.lg;
  static const double s32 = ClientSpacing.xl;
  static const double s40 = 40.0;
  static const double s48 = ClientSpacing.xxl;

  static const Radius r8 = Radius.circular(ClientRadius.xs);
  static const Radius r12 = Radius.circular(ClientRadius.sm);
  static const Radius r14 = Radius.circular(ClientRadius.control);
  static const Radius r16 = Radius.circular(ClientRadius.md);
  static const Radius r20 = Radius.circular(ClientRadius.lg);

  /// Folds onto the card radius — the rider design has no 24.
  static const Radius r24 = Radius.circular(ClientRadius.lg);

  /// Folds onto the hero radius, which the rider design draws at 28.
  static const Radius r32 = Radius.circular(ClientRadius.xl);

  static const Radius rPill = Radius.circular(ClientRadius.pill);

  static const BorderRadius br8 = BorderRadius.all(r8);
  static const BorderRadius br12 = BorderRadius.all(r12);
  static const BorderRadius br14 = BorderRadius.all(r14);
  static const BorderRadius br16 = BorderRadius.all(r16);
  static const BorderRadius br20 = BorderRadius.all(r20);
  static const BorderRadius br24 = BorderRadius.all(r24);
  static const BorderRadius br32 = BorderRadius.all(r32);
  static const BorderRadius brPill = BorderRadius.all(rPill);

  /// The hairline every flat card is drawn with.
  ///
  /// Both designs separate a card from the page with a 1px `--border` rather
  /// than a drop shadow, so a screen of stacked cards reads as a list instead
  /// of a pile of floating tiles. Reach for [softShadow] only when something
  /// really is lifted off the page.
  static Border hairline(BuildContext context) =>
      Border.all(color: ClientColors.borderFor(context));

  /// The rider `0 6px 20px var(--shadow)` lift — list cards and quiet tiles.
  ///
  /// [ClientElevation] scales its alpha in dark mode: a shadow works by
  /// darkening what is behind it, so the light-mode opacity over a dark page is
  /// invisible. That scaling is why these delegate rather than restate.
  static List<BoxShadow> softShadow(BuildContext context) =>
      ClientElevation.sm(context);

  /// The rider `0 14px 30px var(--shadow)` lift — floating chrome.
  static List<BoxShadow> floatingShadow(BuildContext context) =>
      ClientElevation.lg(context);

  /// The coloured halo under the one thing on a screen the captain is meant to
  /// press — the focus card and its call to action.
  ///
  /// Tinted by the element it sits under, never neutral, so it reads as that
  /// element glowing rather than as another grey shadow. The geometry is the
  /// rider design's coloured lift (`0 10px 22px`); dark mode drops the tint and
  /// takes a plain lift, because a coloured glow on the dark page reads as a
  /// smear rather than as separation.
  static List<BoxShadow> glow(
    BuildContext context,
    Color color, {
    double alpha = 0.28,
  }) {
    if (Theme.of(context).brightness == Brightness.dark) {
      return ClientElevation.md(context);
    }
    return [
      BoxShadow(
        color: color.withValues(alpha: alpha),
        blurRadius: 22,
        offset: const Offset(0, 10),
      ),
    ];
  }
}

// ---------------------------------------------------------------------------
// The captain's former tokens, kept for reference.
// Superseded by ClientSpacing / ClientRadius / ClientElevation.
// ---------------------------------------------------------------------------
//
// static const double s4  = 4.0;
// static const double s8  = 8.0;
// static const double s12 = 12.0;
// static const double s16 = 16.0;
// static const double s20 = 20.0;
// static const double s24 = 24.0;
// static const double s32 = 32.0;
// static const double s40 = 40.0;
// static const double s48 = 48.0;
//
// static const Radius r8    = Radius.circular(8);
// static const Radius r12   = Radius.circular(12);
// static const Radius r14   = Radius.circular(14);
// static const Radius r16   = Radius.circular(16);
// static const Radius r20   = Radius.circular(20);
// static const Radius r24   = Radius.circular(24);
// static const Radius r32   = Radius.circular(32);
// static const Radius rPill = Radius.circular(999);
//
// static Border hairline(BuildContext context) {
//   return Border.all(color: CaptainColors.borderFor(context));
// }
//
// static List<BoxShadow> softShadow(BuildContext context) {
//   return [
//     BoxShadow(
//       color: Theme.of(context).brightness == Brightness.dark
//           ? Colors.black.withValues(alpha: 0.3)
//           : CaptainColors.primary.withValues(alpha: 0.05),
//       blurRadius: 15,
//       offset: const Offset(0, 5),
//     ),
//   ];
// }
//
// static List<BoxShadow> floatingShadow(BuildContext context) {
//   return [
//     BoxShadow(
//       color: Theme.of(context).brightness == Brightness.dark
//           ? Colors.black.withValues(alpha: 0.4)
//           : CaptainColors.primary.withValues(alpha: 0.08),
//       blurRadius: 20,
//       offset: const Offset(0, 8),
//       spreadRadius: 2,
//     ),
//   ];
// }
//
// static List<BoxShadow> glow(
//   BuildContext context,
//   Color color, {
//   double alpha = 0.28,
// }) {
//   if (Theme.of(context).brightness == Brightness.dark) {
//     return const [
//       BoxShadow(color: Color(0x66000000), blurRadius: 24, offset: Offset(0, 10)),
//     ];
//   }
//   return [
//     BoxShadow(
//       color: color.withValues(alpha: alpha),
//       blurRadius: 24,
//       offset: const Offset(0, 12),
//       spreadRadius: -8,
//     ),
//   ];
// }
