import 'package:flutter/material.dart';

import '../theme/captain_colors.dart';
import 'captain_trip_stage.dart';

class CaptainTripStagePalette {
  const CaptainTripStagePalette._();

  /// The trip stage never changes hue.
  ///
  /// A card that turns amber while boarding, cyan while underway and red when
  /// cancelled makes the screen feel like it is alarming the captain at every
  /// step of an ordinary trip. The stage is already spelled out by [icon] and
  /// by the stage label next to it, so the surface stays in one calm primary
  /// blue and only the wording and the icon move.
  static Color accent(CaptainTripStage stage) => CaptainColors.primary;

  static Color onAccent(Color accent) {
    return ThemeData.estimateBrightnessForColor(accent) == Brightness.dark
        ? Colors.white
        : const Color(0xFF0F172A);
  }

  static LinearGradient gradient(CaptainTripStage stage) {
    return const LinearGradient(
      colors: [CaptainColors.primary, CaptainColors.primaryDeep],
      begin: AlignmentDirectional.topStart,
      end: AlignmentDirectional.bottomEnd,
    );
  }

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
