import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/dashboard_sparkline.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';

/// Which way a [KpiTrend] should be read, which is not the same as which way it
/// points. Refunds rising is [negative] while revenue rising is [positive], and
/// only the caller knows which figure it is holding — so the tile is told the
/// verdict rather than inferring one from the sign.
enum KpiTrendTone { positive, negative, neutral }

/// A period-over-period movement, formatted and judged by the caller.
///
/// Deliberately free of domain types: this widget lives in `core/` and is used
/// by every module, so it takes strings and a tone rather than a feature's
/// trend entity.
class KpiTrend {
  /// The movement itself — "١٢٪+", "٣ حجوزات−". Already formatted.
  final String label;

  /// What it is measured against: "مقارنة بأمس". Shown under the value when the
  /// tile has room.
  final String? caption;

  final KpiTrendTone tone;

  /// A `DashboardIcons.trendUp` / `trendDown` / `trendFlat` glyph.
  final IconData icon;

  const KpiTrend({
    required this.label,
    required this.icon,
    this.tone = KpiTrendTone.neutral,
    this.caption,
  });
}

/// Unified KPI / stat tile used across every dashboard module.
///
/// A tinted, bordered tile with an icon, a label, an optional [detail] line
/// and a prominent [value]. Pair with [DashboardKpiGrid] for a responsive row
/// of stats. Replaces the per-module tiles that previously diverged in
/// padding, color and typography.
///
/// **Two shapes, one widget.** With neither [trend] nor [sparkline] the tile is
/// the compact row it has always been — icon, label, value — and every existing
/// call site is untouched. Supply either and it becomes the taller stacked
/// form: label and movement on top, the value beneath, and the shape of the
/// last few periods along the bottom. Give the grid a larger `itemExtent`
/// (~132) when using it, since the stacked form needs the height.
class DashboardKpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String? detail;
  final IconData icon;
  final Color? color;

  /// Opens the module this number came from. A KPI that can be drilled into is
  /// the shortest path from "that figure looks wrong" to the screen that
  /// explains it — so when a caller passes this, the tile becomes a real
  /// target: pointer cursor, hover wash and ripple, not just a decorated box.
  final VoidCallback? onTap;

  /// Tooltip for the tappable tile, e.g. "افتح الحجوزات".
  final String? tapHint;

  /// Movement against a previous period. Only supply one that was actually
  /// measured — the dashboard holds no historical snapshots, so a tile with no
  /// derivable baseline shows its value with no arrow rather than a guess.
  final KpiTrend? trend;

  /// The last few periods, oldest first, for the inline shape. Two points
  /// minimum; fewer draws nothing.
  final List<double>? sparkline;

  const DashboardKpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.detail,
    this.color,
    this.onTap,
    this.tapHint,
    this.trend,
    this.sparkline,
  });

  bool get _isStacked => trend != null || (sparkline?.length ?? 0) >= 2;

  @override
  Widget build(BuildContext context) {
    final tile = _isStacked ? _buildStackedTile(context) : _buildTile(context);
    if (onTap == null) return tile;

    final radius = BorderRadius.circular(AppTokens.radiusSmall);
    final tappable = Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(onTap: onTap, borderRadius: radius, child: tile),
    );
    final hint = tapHint;
    return hint == null ? tappable : Tooltip(message: hint, child: tappable);
  }

  /// The taller form: label + movement, then the value, then the shape.
  ///
  /// Shares the compact tile's tint, border and radius exactly — it is the same
  /// tile with more to say, not a second design.
  Widget _buildStackedTile(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tint = color ?? scheme.primary;
    final spark = sparkline;
    final movement = trend;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: DashboardColors.kpiTint(context, tint),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: DashboardColors.kpiBorder(context, tint)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: tint, size: 18),
              const SizedBox(width: AppSpacing.xSmall),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (movement != null) _TrendChip(trend: movement),
            ],
          ),
          const SizedBox(height: AppSpacing.xSmall),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (detail != null || movement?.caption != null)
            Text(
              detail ?? movement!.caption!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          if (spark != null && spark.length >= 2) ...[
            const SizedBox(height: AppSpacing.xSmall),
            // Takes whatever height is left rather than a fixed band, so the
            // tile never overflows when a caller gives the grid a tighter
            // extent than the stacked form would like.
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: DashboardSparkline(values: spark, color: tint),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTile(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = color ?? scheme.primary;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      // The fill and border alphas come from the token layer rather than being
      // fixed: 16/255 of a mid-tone reads as a tint over a white card and as
      // nothing at all over a slate one, so the tile lost its identity in dark
      // mode. [DashboardColors] scales them per brightness.
      decoration: BoxDecoration(
        color: DashboardColors.kpiTint(context, tint),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: DashboardColors.kpiBorder(context, tint)),
      ),
      child: Row(
        children: [
          Icon(icon, color: tint),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                if (detail != null)
                  Text(
                    detail!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.small),
          // Flexible + ellipsis: most values are short numbers, but some
          // callers (e.g. marketplace listing status) pass a full phrase —
          // it must shrink instead of overflowing the row at narrower widths.
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

/// The arrow-and-figure pill in a stacked tile's header.
///
/// Tinted by the caller's verdict rather than by the arrow's direction, so
/// "refunds up 30%" reads red and "revenue up 30%" reads green from the same
/// widget.
class _TrendChip extends StatelessWidget {
  const _TrendChip({required this.trend});

  final KpiTrend trend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = DashboardChartPalette.of(context);
    final tone = switch (trend.tone) {
      KpiTrendTone.positive => palette.positive,
      KpiTrendTone.negative => palette.negative,
      KpiTrendTone.neutral => theme.colorScheme.onSurfaceVariant,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(trend.icon, size: 13, color: tone),
          const SizedBox(width: 2),
          Text(
            trend.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: tone,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Responsive grid of [DashboardKpiCard]s — 4 / 2 / 1 columns by width.
class DashboardKpiGrid extends StatelessWidget {
  final List<Widget> children;
  final double itemExtent;
  final int maxColumns;

  const DashboardKpiGrid({
    super.key,
    required this.children,
    this.itemExtent = 88,
    this.maxColumns = 4,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final base = constraints.maxWidth >= 1040
            ? 4
            : constraints.maxWidth >= 620
            ? 2
            : 1;
        final columns = base > maxColumns ? maxColumns : base;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: children.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: AppSpacing.small,
            mainAxisSpacing: AppSpacing.small,
            mainAxisExtent: itemExtent,
          ),
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}
