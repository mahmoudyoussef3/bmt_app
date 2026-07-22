import 'package:flutter/material.dart';

import '../theme/captain_colors.dart';
import 'captain_trip_stage.dart';

/// The colour each [CaptainTripStage] is drawn in, in one place.
///
/// The home focus card and the trip execution canopy are the same trip seen
/// from two screens, and a captain glancing at either while at the wheel should
/// recognise the state from its colour before reading a word of it. They
/// previously picked their own: home painted every stage the same brand blue,
/// while the execution screen hardcoded `Colors.orange` for boarding — so the
/// same trip changed colour when opened.
///
/// The hues match what `CaptainStatusChip` already assigns to the underlying
/// statuses, so the chip and the surface it sits on can never disagree.
class CaptainTripStagePalette {
  const CaptainTripStagePalette._();

  /// The stage's hue.
  ///
  /// Boarding and underway are deliberately a step darker than the
  /// `CaptainColors.warning` / `primaryBright` they read as. Those two are tuned
  /// to be *tints* — a chip background, a progress bar — and this colour also
  /// has to carry white label text on a filled button. White on Amber 500 is
  /// 2.1:1 and on Sky 500 is 2.9:1, both under the 3:1 AA floor for large bold
  /// text; Amber 600 and Sky 600 clear it while staying unmistakably the same
  /// colour. See [onAccent] for the foreground rule that backs this up.
  static Color accent(CaptainTripStage stage) => switch (stage) {
    // Operations hasn't released it — nothing here belongs to the captain yet,
    // so it stays off the brand entirely.
    CaptainTripStage.awaitingRelease => CaptainColors.offline,
    CaptainTripStage.awaitingWindow ||
    CaptainTripStage.readyToBoard => CaptainColors.primary,
    CaptainTripStage.boarding => const Color(0xFFD97706), // Amber 600
    CaptainTripStage.underway => const Color(0xFF0284C7), // Sky 600
    CaptainTripStage.finished => CaptainColors.offline,
    CaptainTripStage.cancelled => CaptainColors.error,
  };

  /// The text/icon colour to use on a surface filled with [accent].
  ///
  /// Measured rather than assumed: the stage colours span slate to amber to
  /// blue, and hardcoding white on all of them is what puts a label at 2:1 on
  /// the amber ones.
  static Color onAccent(Color accent) {
    return ThemeData.estimateBrightnessForColor(accent) == Brightness.dark
        ? Colors.white
        : const Color(0xFF0F172A);
  }

  /// The canopy gradient for [stage] — [accent] run into a deeper partner so a
  /// full-bleed header has depth instead of reading as a flat swatch.
  static LinearGradient gradient(CaptainTripStage stage) {
    final base = accent(stage);
    return LinearGradient(
      colors: [base, _deepen(stage, base)],
      begin: AlignmentDirectional.topStart,
      end: AlignmentDirectional.bottomEnd,
    );
  }

  /// Live stages resolve into the brand blue so the screen still reads as this
  /// app; the rest simply darken their own hue.
  static Color _deepen(CaptainTripStage stage, Color base) => switch (stage) {
    CaptainTripStage.underway => CaptainColors.primary,
    CaptainTripStage.boarding => const Color(0xFFB45309), // Amber 700
    CaptainTripStage.awaitingWindow ||
    CaptainTripStage.readyToBoard => CaptainColors.primaryDeep,
    _ => Color.lerp(base, Colors.black, 0.25)!,
  };

  /// The icon that stands for [stage] wherever it is shown as a status.
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
