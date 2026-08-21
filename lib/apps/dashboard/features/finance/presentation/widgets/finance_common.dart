import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/route_direction_text.dart';

import '../../domain/entities/finance_analytics.dart';
import '../../domain/entities/finance_entities.dart';
import 'finance_format.dart';

/// Period-over-period change, rendered as a directional pill.
///
/// Falling revenue is red and rising revenue is green — except for costs, where
/// [inverted] flips it, because a refund line growing 40% is not good news
/// dressed in green.
class FinanceDeltaBadge extends StatelessWidget {
  final double? change;
  final bool inverted;
  final String? caption;

  const FinanceDeltaBadge({
    super.key,
    required this.change,
    this.inverted = false,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final value = change;

    if (value == null) {
      return Text(
        caption ?? 'لا توجد فترة سابقة للمقارنة',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
      );
    }

    final palette = DashboardChartPalette.of(context);
    final isUp = value >= 0;
    final isGood = inverted ? !isUp : isUp;
    final color = value == 0
        ? palette.neutral
        : isGood
        ? palette.positive
        : palette.negative;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.small,
            vertical: 3,
          ),
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withAlpha(70)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                FinanceFormat.changeLabel(value),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        if (caption != null) ...[
          const SizedBox(width: AppSpacing.small),
          Flexible(
            child: Text(
              caption!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ],
    );
  }
}

/// A ranked money list: label, share bar, formatted amount and percentage.
///
/// The shared [DashboardRankedBars] prints a bare integer, which is right for
/// counts and wrong for currency — a finance ranking has to say "12,340 ج.م —
/// 24%", not "12340". Same visual language, money-aware trailing block.
///
/// The label column is proportional rather than a fixed 140px. A route label in
/// this database is the whole journey as free text — "Obour, QH, Egypt →
/// American University in Cairo (AUC) - New Cairo, QH, Egypt" — and 140px of it
/// is "Obour, QH, Egyp…", which ranks corridors the reader cannot identify.
class FinanceRankedList extends StatelessWidget {
  final List<FinanceBreakdownRow> rows;
  final double total;
  final int limit;
  final bool showCount;
  final String emptyLabel;

  /// Renders each label as an origin → destination pair. Set on the route
  /// ranking, where the label is a stored `'A → B'` string that reverses under
  /// bidi if it is printed as-is.
  final bool labelsAreRoutes;

  const FinanceRankedList({
    super.key,
    required this.rows,
    required this.total,
    this.limit = 6,
    this.showCount = true,
    this.labelsAreRoutes = false,
    this.emptyLabel = 'لا توجد بيانات في هذه الفترة',
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final visible = rows.where((row) => row.amount > 0).take(limit).toList();

    if (visible.isEmpty) {
      return Text(
        emptyLabel,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
      );
    }

    final peak = visible.first.amount;

    return Column(
      children: [
        for (final (index, row) in visible.indexed)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: labelsAreRoutes
                      ? FinanceRouteLabel(label: row.label)
                      : Text(
                          row.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                ),
                const SizedBox(width: AppSpacing.small),
                Expanded(
                  flex: 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: peak <= 0
                          ? 0
                          : (row.amount / peak).clamp(0, 1).toDouble(),
                      minHeight: 10,
                      backgroundColor: scheme.surfaceContainerHighest,
                      color: DashboardChartPalette.of(
                        context,
                      ).categoryAt(index),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.small),
                SizedBox(
                  width: 132,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        FinanceFormat.money(row.amount),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        showCount
                            ? '${FinanceFormat.percent(row.shareOf(total))} • ${FinanceFormat.count(row.count)} عملية'
                            : FinanceFormat.percent(row.shareOf(total)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A stored `'origin → destination'` route string, taken apart and recomposed
/// so it still reads forwards.
///
/// The database keeps the pair already joined, and a joined string is a single
/// bidi paragraph: with Latin place names — what the geocoder returns for most
/// Egyptian stops — UAX#9 resolves the whole line left-to-right and the arrow
/// ends up pointing at the origin. Splitting it and handing the two names to
/// [RouteDirectionText] isolates each one and picks the arrow from the ambient
/// direction. The full original stays in the tooltip, since the split is for
/// reading and never for identity.
class FinanceRouteLabel extends StatelessWidget {
  const FinanceRouteLabel({super.key, required this.label, this.style});

  final String label;
  final TextStyle? style;

  static const _separators = ['→', '←', '->', '<-'];

  @override
  Widget build(BuildContext context) {
    final effective = style ?? Theme.of(context).textTheme.bodySmall;

    for (final separator in _separators) {
      final index = label.indexOf(separator);
      if (index <= 0) continue;
      final head = label.substring(0, index).trim();
      final tail = label.substring(index + separator.length).trim();
      if (head.isEmpty || tail.isEmpty) continue;

      final reversed = separator == '←' || separator == '<-';
      return Tooltip(
        message: label,
        child: RouteDirectionText(
          origin: reversed ? tail : head,
          destination: reversed ? head : tail,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: effective,
        ),
      );
    }

    return Tooltip(
      message: label,
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: effective,
      ),
    );
  }
}

/// Compact trend line for hero tiles — no axes, no grid, just the shape of the
/// period. Deliberately unlabelled: it is a glance, and every number it implies
/// is spelled out beside it.
class FinanceSparkline extends StatelessWidget {
  final List<double> values;
  final Color color;
  final double height;

  const FinanceSparkline({
    super.key,
    required this.values,
    required this.color,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    if (values.length < 2) return SizedBox(height: height);

    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final span = maxValue - minValue;

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: span == 0 ? minValue - 1 : minValue - span * 0.15,
          maxY: span == 0 ? maxValue + 1 : maxValue + span * 0.15,
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < values.length; i++)
                  FlSpot(i.toDouble(), values[i]),
              ],
              isCurved: true,
              curveSmoothness: 0.25,
              color: color,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: color.withAlpha(36)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Status pill shared by the ledger table and the transaction breakdowns.
class FinanceStatusBadge extends StatelessWidget {
  final PaymentStatus status;

  const FinanceStatusBadge({super.key, required this.status});

  /// Takes a [context] because the chart palette resolves per brightness —
  /// the payment colours have to match the chart segments on the same screen.
  static Color colorOf(BuildContext context, PaymentStatus status) {
    final palette = DashboardChartPalette.of(context);
    return switch (status) {
      PaymentStatus.success => palette.positive,
      PaymentStatus.pending => palette.warning,
      PaymentStatus.cancelled => palette.negative,
      PaymentStatus.refunded => palette.accent,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = colorOf(context, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Two-column figure row used by the statement and the comparison tables.
class FinanceFigureRow extends StatelessWidget {
  final String label;
  final String value;
  final String? trailing;
  final bool emphasised;
  final bool muted;
  final Color? valueColor;

  const FinanceFigureRow({
    super.key,
    required this.label,
    required this.value,
    this.trailing,
    this.emphasised = false,
    this.muted = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final labelStyle = emphasised
        ? theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)
        : theme.textTheme.bodyMedium?.copyWith(
            color: muted ? scheme.onSurfaceVariant : null,
          );
    final valueStyle = emphasised
        ? theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: valueColor,
          )
        : theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor ?? (muted ? scheme.onSurfaceVariant : null),
          );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: labelStyle)),
          if (trailing != null) ...[
            Text(
              trailing!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: AppSpacing.medium),
          ],
          Text(value, style: valueStyle),
        ],
      ),
    );
  }
}
