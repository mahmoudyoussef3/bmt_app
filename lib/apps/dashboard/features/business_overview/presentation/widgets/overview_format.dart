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

String count(num value) => _grouped.format(value.round());

/// `68%` from a `0..1` ratio.
String percent(double ratio) => '${(ratio * 100).round()}%';

/// `—` when a ratio could not be measured. Used everywhere a null means "no
/// data", never "zero".
String percentOrDash(double? ratio) => ratio == null ? '—' : percent(ratio);

/// Turns a measured [MetricTrend] into the tile's chip, in **الرئيسية's
/// wording**: a magnitude and the window it is measured against, in one
/// phrase — «١٢% عن الشهر السابق», «كما أمس».
///
/// Home writes its movements this way and this page used to write them as a
/// bare «١٢%» with the comparison demoted to a caption line underneath. Two
/// screens the same operator reads back to back should not describe the same
/// arithmetic in two grammars, and the caption was the first thing to be
/// clipped whenever a tile ran short.
///
/// [upIsGood] is the caller's verdict, not the arithmetic's: refunds rising
/// and revenue rising are the same arrow and opposite news.
///
/// The label carries **magnitude only** — the arrow carries direction. A
/// literal `+`/`−` beside digits inside an RTL line is reordered by the bidi
/// algorithm and the sign can land on the wrong side of the number; an arrow
/// icon has no direction to lose. When there is no baseline to divide by, the
/// absolute change is shown instead, formatted by [absolute].
KpiTrend? kpiTrendFrom(
  MetricTrend? trend, {
  required bool upIsGood,
  String Function(double value)? absolute,
}) {
  if (trend == null) return null;

  final against = 'عن ${trend.previousLabel}';
  if (trend.direction == TrendDirection.flat) {
    return KpiTrend(
      label: 'كما ${trend.previousLabel}',
      icon: DashboardIcons.trendFlat,
      tone: KpiTrendTone.neutral,
    );
  }

  final ratio = trend.changeRatio;
  final magnitude = ratio != null
      ? percent(ratio.abs())
      : (absolute ?? count)(trend.delta.abs());
  final isUp = trend.direction == TrendDirection.up;

  return KpiTrend(
    label: '$magnitude $against',
    icon: isUp ? DashboardIcons.trendUp : DashboardIcons.trendDown,
    tone: (isUp == upIsGood) ? KpiTrendTone.positive : KpiTrendTone.negative,
  );
}

/// The `value` list a sparkline takes, from a daily series — or null when the
/// series never left zero.
///
/// An all-zero window is a true measurement, but a straight line along the
/// floor is not a useful drawing of it: on a tile whose value already reads
/// «—» because nothing was measurable, that line says the opposite of the
/// number above it. No shape is the honest rendering of no movement.
List<double>? sparkValues(List<DailyMetric> series) {
  if (series.length < 2) return null;
  if (series.every((point) => point.value == 0)) return null;
  return [for (final point in series) point.value];
}
