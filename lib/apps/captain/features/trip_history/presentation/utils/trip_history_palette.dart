import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';

class TripHistoryPalette {
  const TripHistoryPalette._();

  static const Color accent = CaptainColors.primary;

  static const Color accentDeep = CaptainColors.primaryDeep;

  /// A trip that came up short is still said in brand blue, not amber: history
  /// is a finished record, so a shortfall is something to read — not an alarm
  /// the captain can still act on. The words carry the fact; the colour only
  /// separates it from the muted metadata around it.
  static const Color attention = accent;

  static Color neutral(BuildContext context) =>
      CaptainColors.textSecondaryFor(context);

  static const LinearGradient markGradient = LinearGradient(
    colors: [accent, accentDeep],
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
  );
}
