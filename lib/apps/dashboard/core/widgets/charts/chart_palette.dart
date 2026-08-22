import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_dark_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_light_colors.dart';

/// The dashboard's single chart colour vocabulary.
///
/// Every chart in every module reads its colours from here, so "positive" means
/// the same thing on the fleet donut as it does on the finance breakdown — and
/// the same thing as a "resolved" badge elsewhere on the screen, because both
/// resolve to the shared status palette.
///
/// ## Why this is resolved per brightness
///
/// These used to be six `static const` values taken from the light `on*Container`
/// tones (`#164E63`, `#78350F`, `#7F1D1D`, …). Those are near-black inks chosen
/// to sit *on* a pale container; painted as chart segments on a slate page they
/// are barely distinguishable from the page itself, so in dark mode every donut
/// and bar chart in the dashboard was rendering as a dark smudge. A chart fill
/// has the page behind it, not a container, so it needs the mid-weight `*Ink`
/// tone in dark and the deeper `on*Container` tone in light.
///
/// Call [of] once per `build` and read fields off the result.
@immutable
class DashboardChartPalette {
  const DashboardChartPalette._({
    required this.positive,
    required this.warning,
    required this.negative,
    required this.active,
    required this.neutral,
    required this.accent,
    required this.sequential,
  });

  /// Healthy / available / succeeded.
  final Color positive;

  /// Needs attention / pending / expiring.
  final Color warning;

  /// Failed / rejected / suspended.
  final Color negative;

  /// In use / assigned / active — the "working normally" accent.
  final Color active;

  /// Idle / archived / not applicable.
  final Color neutral;

  /// Secondary emphasis, for a category that is none of the above.
  final Color accent;

  /// Five-stop, low→high intensity **blue** ramp for data that is ordinal or
  /// otherwise a single dimension in disguise (occupancy bands, a status
  /// progression from scheduled to in-progress) rather than genuinely
  /// unrelated categories.
  ///
  /// [categorical] answers "which kind" with one hue per kind; this answers
  /// "how much" with one hue, shaded by degree — the calmer, single-brand
  /// read a dense admin console wants instead of six unrelated hues (several
  /// of which land in the same red used for destructive actions) standing in
  /// for what is really "a little" through "a lot".
  final List<Color> sequential;

  static final DashboardChartPalette _light = DashboardChartPalette._(
    positive: DashboardLightColors.onSuccessContainer,
    warning: DashboardLightColors.onWarningContainer,
    negative: DashboardLightColors.onDangerContainer,
    active: DashboardLightColors.onInfoContainer,
    neutral: DashboardLightColors.onNeutralContainer,
    accent: DashboardLightColors.onSpecialContainer,
    // Lightest → darkest brand blue, so "low" recedes toward the page and
    // "high" reads as the most saturated, most present tone — the ordering a
    // light page needs. Anchored on the same two tones [kpiTint]/badges
    // already use for this hue, just interpolated rather than jumping
    // straight from one to the other.
    sequential: _ramp(
      DashboardLightColors.primaryContainer,
      DashboardLightColors.onPrimaryContainer,
    ),
  );

  static final DashboardChartPalette _dark = DashboardChartPalette._(
    positive: DashboardDarkColors.successInk,
    warning: DashboardDarkColors.warningInk,
    negative: DashboardDarkColors.dangerInk,
    active: DashboardDarkColors.primaryAccent,
    neutral: DashboardDarkColors.onNeutralContainer,
    accent: DashboardDarkColors.special,
    // Same idea, mirrored: a dark page needs "low" to sink toward the dark
    // container tone and "high" to rise toward the bright accent ink, which
    // is the pairing [DashboardDarkColors] itself already inverts for this reason.
    sequential: _ramp(
      DashboardDarkColors.primaryContainer,
      DashboardDarkColors.primaryAccent,
    ),
  );

  static List<Color> _ramp(Color from, Color to, {int steps = 5}) => [
    for (var i = 0; i < steps; i++) Color.lerp(from, to, i / (steps - 1))!,
  ];

  static DashboardChartPalette of(BuildContext context) =>
      resolve(Theme.of(context).brightness);

  static DashboardChartPalette resolve(Brightness brightness) =>
      brightness == Brightness.dark ? _dark : _light;

  /// Ordered palette for charts whose categories carry no status meaning
  /// (e.g. revenue by route). Cycles when there are more series than colours.
  List<Color> get categorical => [
    active,
    positive,
    accent,
    warning,
    negative,
    neutral,
  ];

  Color categoryAt(int index) {
    final colors = categorical;
    return colors[index % colors.length];
  }
}
