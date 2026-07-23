import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/colors.dart';

/// The dashboard's single chart colour vocabulary.
///
/// Every chart in every module reads its colours from here, so "green" means
/// the same thing on the fleet donut as it does on the finance breakdown. Chart
/// fills are the darker `on*Container` tones rather than the pale container
/// tints: the container colours are tuned to sit *behind* text and are too low
/// contrast to read as chart segments, especially in dark mode.
class DashboardChartPalette {
  const DashboardChartPalette._();

  /// Healthy / available / succeeded.
  static const Color positive = AppStatusColors.onSuccessContainer;

  /// Needs attention / pending / expiring.
  static const Color warning = AppStatusColors.onWarningContainer;

  /// Failed / rejected / suspended.
  static const Color negative = AppStatusColors.onErrorContainer;

  /// In use / assigned / active — the "working normally" accent.
  static const Color active = AppStatusColors.onInfoContainer;

  /// Idle / archived / not applicable.
  static const Color neutral = AppStatusColors.onNeutralContainer;

  /// Secondary emphasis, for a category that is none of the above.
  static const Color accent = AppStatusColors.onSpecialContainer;

  /// Ordered palette for charts whose categories carry no status meaning
  /// (e.g. revenue by route). Cycles when there are more series than colours.
  static const List<Color> categorical = [
    active,
    positive,
    accent,
    warning,
    negative,
    neutral,
  ];

  static Color categoryAt(int index) => categorical[index % categorical.length];
}
