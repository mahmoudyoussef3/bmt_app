import 'package:intl/intl.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_kpi_card.dart';

import '../../domain/entities/business_metric.dart';

/// How the executive page writes numbers.
///
/// Grouping comes from the `en` pattern rather than `ar_EG`, which would render
/// Arabic-Indic digits (١٢٬٤٠٠). The rest of the dashboard prints Western
/// digits, and one page switching numeral systems is the sort of inconsistency
/// that makes an owner distrust the figure before they read it.
final _grouped = NumberFormat.decimalPattern('en');

/// `12,400 ج.م` — amount then symbol, matching every other dashboard module.
/// Rounded to whole pounds: piastres on an executive summary are noise.
String money(num value) => '${_grouped.format(value.round())} ج.م';

/// A signed amount, for figures that can legitimately fall — a wallet balance
/// moving, a period-over-period delta.
String signedMoney(num value) {
  if (value == 0) return money(0);
  return '${value > 0 ? '+' : '−'}${money(value.abs())}';
}

String count(num value) => _grouped.format(value.round());

/// `68%` from a `0..1` ratio.
String percent(double ratio) => '${(ratio * 100).round()}%';

/// `—` when a ratio could not be measured. Used everywhere a null means "no
/// data", never "zero".
String percentOrDash(double? ratio) => ratio == null ? '—' : percent(ratio);

/// Turns a measured [MetricTrend] into the tile's chip.
///
/// [upIsGood] is the caller's verdict, not the arithmetic's: refunds rising and
/// revenue rising are the same arrow and opposite news.
///
/// The label carries **magnitude only** — the arrow already carries direction,
/// and a `+`/`−` sign next to an arrow inside an RTL line is one glyph too many
/// pointing at the same fact. When there is no baseline to divide by, the
/// absolute change is shown instead, formatted by [absolute].
KpiTrend? kpiTrendFrom(
  MetricTrend? trend, {
  required bool upIsGood,
  String Function(double value)? absolute,
}) {
  if (trend == null) return null;

  final ratio = trend.changeRatio;
  final direction = trend.direction;
  final label = ratio != null
      ? percent(ratio.abs())
      : (absolute ?? count)(trend.delta.abs());

  final tone = switch (direction) {
    TrendDirection.flat => KpiTrendTone.neutral,
    TrendDirection.up => upIsGood ? KpiTrendTone.positive : KpiTrendTone.negative,
    TrendDirection.down => upIsGood
        ? KpiTrendTone.negative
        : KpiTrendTone.positive,
  };

  final icon = switch (direction) {
    TrendDirection.up => DashboardIcons.trendUp,
    TrendDirection.down => DashboardIcons.trendDown,
    TrendDirection.flat => DashboardIcons.trendFlat,
  };

  return KpiTrend(
    label: direction == TrendDirection.flat ? 'بدون تغيير' : label,
    icon: icon,
    tone: tone,
    caption: 'مقارنة بـ${trend.previousLabel}',
  );
}

/// The `value` list a sparkline takes, from a daily series.
List<double> sparkValues(List<DailyMetric> series) => [
  for (final point in series) point.value,
];
