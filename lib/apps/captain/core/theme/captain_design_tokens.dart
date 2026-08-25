import 'package:flutter/material.dart';

import 'captain_colors.dart';

class CaptainDesignTokens {
  CaptainDesignTokens._();

  static const double s4 = 4.0;
  static const double s8 = 8.0;
  static const double s12 = 12.0;
  static const double s16 = 16.0;
  static const double s20 = 20.0;
  static const double s24 = 24.0;
  static const double s32 = 32.0;
  static const double s40 = 40.0;
  static const double s48 = 48.0;

  static const Radius r8 = Radius.circular(8);
  static const Radius r12 = Radius.circular(12);
  static const Radius r14 = Radius.circular(14);
  static const Radius r16 = Radius.circular(16);

  static const Radius r20 = Radius.circular(20);

  static const Radius r24 = Radius.circular(24);
  static const Radius r32 = Radius.circular(32);

  static const Radius rPill = Radius.circular(999);

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
  /// The design separates cards from the page with a 1px `--border` rather than
  /// a drop shadow, so a screen of stacked cards reads as a list instead of a
  /// pile of floating tiles. Reach for [softShadow] only when something really
  /// is lifted off the page.
  static Border hairline(BuildContext context) {
    return Border.all(color: CaptainColors.borderFor(context));
  }

  static List<BoxShadow> softShadow(BuildContext context) {
    return [
      BoxShadow(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.black.withValues(alpha: 0.3)
            : CaptainColors.primary.withValues(alpha: 0.05),
        blurRadius: 15,
        offset: const Offset(0, 5),
      ),
    ];
  }

  static List<BoxShadow> floatingShadow(BuildContext context) {
    return [
      BoxShadow(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.black.withValues(alpha: 0.4)
            : CaptainColors.primary.withValues(alpha: 0.08),
        blurRadius: 20,
        offset: const Offset(0, 8),
        spreadRadius: 2,
      ),
    ];
  }

  /// The coloured halo under the one thing on a screen the captain is meant to
  /// press — the focus card and its call to action. It is tinted by the element
  /// it sits under, never neutral, so it reads as that element glowing rather
  /// than as another grey shadow.
  static List<BoxShadow> glow(
    BuildContext context,
    Color color, {
    double alpha = 0.28,
  }) {
    if (Theme.of(context).brightness == Brightness.dark) {
      return const [
        BoxShadow(color: Color(0x66000000), blurRadius: 24, offset: Offset(0, 10)),
      ];
    }
    return [
      BoxShadow(
        color: color.withValues(alpha: alpha),
        blurRadius: 24,
        offset: const Offset(0, 12),
        spreadRadius: -8,
      ),
    ];
  }
}
