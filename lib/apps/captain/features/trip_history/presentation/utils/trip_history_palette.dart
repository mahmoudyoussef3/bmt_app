import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';

class TripHistoryPalette {
  const TripHistoryPalette._();

  static const Color accent = CaptainColors.primary;

  static const Color accentDeep = CaptainColors.primaryDeep;

  static const Color attention = CaptainColors.warning;

  static Color neutral(BuildContext context) =>
      CaptainColors.textSecondaryFor(context);

  static Color wash(BuildContext context) {
    return accent.withValues(
      alpha: Theme.of(context).brightness == Brightness.dark ? 0.16 : 0.05,
    );
  }

  static Color boarding(double rate) => rate >= 1 ? accent : attention;

  static const LinearGradient markGradient = LinearGradient(
    colors: [accent, accentDeep],
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
  );

  static const LinearGradient shortfallGradient = LinearGradient(
    colors: [attention, Color(0xFFB45309)],
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
  );

  static LinearGradient mark({required int boarded, required int total}) {
    if (total == 0 || boarded >= total) return markGradient;
    return shortfallGradient;
  }
}
