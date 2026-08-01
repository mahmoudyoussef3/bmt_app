import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/app_dark_colors.dart';
import 'package:bmt_app/core/theme/app_light_colors.dart';

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

  static const DashboardChartPalette _light = DashboardChartPalette._(
    positive: AppLightColors.onSuccessContainer,
    warning: AppLightColors.onWarningContainer,
    negative: AppLightColors.onDangerContainer,
    active: AppLightColors.onInfoContainer,
    neutral: AppLightColors.onNeutralContainer,
    accent: AppLightColors.onSpecialContainer,
  );

  static const DashboardChartPalette _dark = DashboardChartPalette._(
    positive: AppDarkColors.successInk,
    warning: AppDarkColors.warningInk,
    negative: AppDarkColors.dangerInk,
    active: AppDarkColors.primaryAccent,
    neutral: AppDarkColors.onNeutralContainer,
    accent: AppDarkColors.special,
  );

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
