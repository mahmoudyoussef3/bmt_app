import 'package:flutter/material.dart';

import '../theme/captain_colors.dart';
import 'captain_trip_stage.dart';

class CaptainTripStagePalette {
  const CaptainTripStagePalette._();

  static Color accent(CaptainTripStage stage) => switch (stage) {
    CaptainTripStage.awaitingRelease => CaptainColors.offline,
    CaptainTripStage.awaitingWindow ||
    CaptainTripStage.readyToBoard => CaptainColors.primary,
    CaptainTripStage.boarding => const Color(0xFFD97706),
    CaptainTripStage.underway => const Color(0xFF0284C7),
    CaptainTripStage.finished => CaptainColors.offline,
    CaptainTripStage.cancelled => CaptainColors.error,
  };

  static Color onAccent(Color accent) {
    return ThemeData.estimateBrightnessForColor(accent) == Brightness.dark
        ? Colors.white
        : const Color(0xFF0F172A);
  }

  static LinearGradient gradient(CaptainTripStage stage) {
    final base = accent(stage);
    return LinearGradient(
      colors: [base, _deepen(stage, base)],
      begin: AlignmentDirectional.topStart,
      end: AlignmentDirectional.bottomEnd,
    );
  }

  static Color _deepen(CaptainTripStage stage, Color base) => switch (stage) {
    CaptainTripStage.underway => CaptainColors.primary,
    CaptainTripStage.boarding => const Color(0xFFB45309),
    CaptainTripStage.awaitingWindow ||
    CaptainTripStage.readyToBoard => CaptainColors.primaryDeep,
    _ => Color.lerp(base, Colors.black, 0.25)!,
  };

  static IconData icon(CaptainTripStage stage) => switch (stage) {
    CaptainTripStage.awaitingRelease => Icons.lock_clock_rounded,
    CaptainTripStage.awaitingWindow => Icons.hourglass_top_rounded,
    CaptainTripStage.readyToBoard => Icons.how_to_reg_rounded,
    CaptainTripStage.boarding => Icons.people_alt_rounded,
    CaptainTripStage.underway => Icons.directions_bus_filled_rounded,
    CaptainTripStage.finished => Icons.check_circle_rounded,
    CaptainTripStage.cancelled => Icons.cancel_rounded,
  };
}
