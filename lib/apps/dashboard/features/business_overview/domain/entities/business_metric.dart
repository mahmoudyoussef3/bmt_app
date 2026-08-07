/// The measurement vocabulary the executive overview is written in.
///
/// Pure Dart on purpose: a trend is arithmetic over two periods, and how it is
/// *drawn* — arrow, tint, sparkline — belongs to the presentation layer.
library;

/// One day of a daily series.
///
/// [value] carries whatever the series measures: pounds for revenue, a count
/// for bookings, a `0..1` ratio for occupancy. Quiet days are present as zeros
/// rather than omitted, so a sparkline keeps its true shape instead of
/// compressing a dead week into a straight line.
class DailyMetric {
  final DateTime day;
  final double value;

  const DailyMetric({required this.day, required this.value});
}

enum TrendDirection { up, down, flat }

/// A period-over-period comparison of one figure.
///
/// Only ever constructed from two windows that were both actually measured. The
/// dashboard has no historical snapshot table, so any trend shown here is
/// derived by re-bucketing the same rows the modules already loaded — which is
/// also why [changeRatio] is allowed to be null instead of inventing a
/// percentage against an empty baseline.
class MetricTrend {
  final double current;
  final double previous;

  /// What [previous] covers, in Arabic — "أمس", "الأسبوع الماضي". Rendered
  /// beside the arrow so a reader never has to guess the comparison window.
  final String previousLabel;

  const MetricTrend({
    required this.current,
    required this.previous,
    required this.previousLabel,
  });

  double get delta => current - previous;

  /// Relative change, or null when there is nothing to divide by.
  ///
  /// A percentage against a zero baseline is either infinity or a fabrication;
  /// callers fall back to the absolute [delta], which is always true.
  double? get changeRatio {
    if (previous == 0) return null;
    return delta / previous;
  }

  /// Movement under half a percent reads as flat.
  ///
  /// Without a dead band, floating-point noise on a quiet day renders as a
  /// green arrow, which is worse than no arrow at all.
  TrendDirection get direction {
    if (previous == 0) {
      if (current == 0) return TrendDirection.flat;
      return current > 0 ? TrendDirection.up : TrendDirection.down;
    }
    final ratio = delta / previous;
    if (ratio.abs() < 0.005) return TrendDirection.flat;
    return ratio > 0 ? TrendDirection.up : TrendDirection.down;
  }

  bool get isFlat => direction == TrendDirection.flat;
}
