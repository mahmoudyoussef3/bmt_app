import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/dashboard_sparkline.dart';
import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';

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

  AppStatusTone get _statusTone => switch (tone) {
    KpiTrendTone.positive => AppStatusTone.success,
    KpiTrendTone.negative => AppStatusTone.error,
    KpiTrendTone.neutral => AppStatusTone.neutral,
  };
}

/// Unified KPI / stat tile used across every dashboard module.
///
/// A plain surface card — border and radius carry its shape, not a tinted
/// background — with a tinted glyph chip, a label, an optional [detail] line
/// and a prominent [value]. Pair with [DashboardKpiGrid] for a responsive row
/// of stats.
///
/// **Two shapes, one widget.** With neither [trend] nor [sparkline] the tile is
/// the compact row it has always been — glyph, label, value — and every
/// existing call site is untouched. Supply either and it becomes the taller
/// stacked form: label and movement on top, the value beneath, and the shape of
/// the last few periods along the bottom. Give the grid a larger `itemExtent`
/// (~132) when using it, since the stacked form needs the height.
///
/// ## Where the colour goes
///
/// [color] tints **the glyph and its chip**, and nothing else. The EWT
/// redesign's rule is "a KPI is a plain card, and the only colour on it is the
/// trend chip"; a glyph in a tinted square is that rule's other half — it gives
/// the tile an anchor the eye lands on before the digits, in the same shape the
/// attention queues and the record tiles use, without turning four ordinary
/// numbers into four coloured panels.
///
/// ## Why it reacts to a pointer
///
/// A KPI that can be drilled into is the shortest path from "that figure looks
/// wrong" to the screen that explains it. When [onTap] is given the tile lifts
/// on hover — a stronger border, a deeper shadow — so a reader can tell which
/// of the four numbers in front of them is a door and which is a fact.
class DashboardKpiCard extends StatefulWidget {
  final String label;
  final String value;
  final String? detail;
  final IconData icon;
  final Color? color;

  /// Opens the module this number came from.
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

  /// Forces the taller stacked form — big 27px value, label on its own row —
  /// even with no [trend]/[sparkline] to trigger it. For a strip that wants
  /// the EWT redesign's hero-KPI weight (Home's four numbers) without a
  /// movement figure this dashboard has no historical snapshot to back.
  final bool emphasized;

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
    this.emphasized = false,
  });

  @override
  State<DashboardKpiCard> createState() => _DashboardKpiCardState();
}

class _DashboardKpiCardState extends State<DashboardKpiCard> {
  bool _hovered = false;

  bool get _isStacked =>
      widget.emphasized ||
      widget.trend != null ||
      (widget.sparkline?.length ?? 0) >= 2;

  @override
  Widget build(BuildContext context) {
    final tile = _isStacked ? _buildStackedTile(context) : _buildTile(context);
    if (widget.onTap == null) return tile;

    final radius = BorderRadius.circular(12);
    final tappable = MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(onTap: widget.onTap, borderRadius: radius, child: tile),
      ),
    );
    final hint = widget.tapHint;
    return hint == null ? tappable : Tooltip(message: hint, child: tappable);
  }

  void _setHovered(bool value) {
    if (_hovered == value) return;
    setState(() => _hovered = value);
  }

  BoxDecoration _cardDecoration(BuildContext context) => BoxDecoration(
    color: DashboardColors.panel(context),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: _hovered
          ? DashboardColors.borderStrong(context)
          : DashboardColors.border(context),
    ),
    boxShadow: _hovered
        ? DashboardColors.floatingShadow(context)
        : DashboardColors.panelShadow(context),
  );

  /// The taller form: glyph + label + movement, then the value, then the shape.
  Widget _buildStackedTile(BuildContext context) {
    final theme = Theme.of(context);
    final spark = widget.sparkline;
    final movement = widget.trend;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 11),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _GlyphChip(icon: widget.icon, color: widget.color, size: 28),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: DashboardColors.mutedInk(context),
                  ),
                ),
              ),
              if (movement != null) ...[
                const SizedBox(width: 6),
                Flexible(child: _TrendChip(trend: movement)),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.displayMedium?.copyWith(
              fontSize: 27,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              height: 1.1,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (widget.detail != null || movement?.caption != null)
            Text(
              widget.detail ?? movement!.caption!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: DashboardColors.faintInk(context),
              ),
            ),
          if (spark != null && spark.length >= 2) ...[
            const SizedBox(height: AppSpacing.xSmall),
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: DashboardSparkline(
                  values: spark,
                  color: widget.color ?? DashboardColors.accentFill(context),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTile(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      padding: const EdgeInsets.fromLTRB(13, 13, 13, 12),
      decoration: _cardDecoration(context),
      child: Row(
        children: [
          _GlyphChip(icon: widget.icon, color: widget.color, size: 26),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: DashboardColors.mutedInk(context),
                  ),
                ),
                if (widget.detail != null)
                  Text(
                    widget.detail!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: DashboardColors.faintInk(context),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.small),
          Flexible(
            child: Text(
              widget.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: theme.textTheme.displayMedium?.copyWith(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The tile's anchor: the metric's glyph on a wash of its own colour, inside a
/// hairline of the same hue.
///
/// The same square the attention queues and [OverviewRecordTile] draw, at KPI
/// scale — which is what makes a number tile and a queue tile read as two
/// members of one family rather than two designs. With no [color] it falls back
/// to the console's neutral chip, so an untinted caller still gets the shape.
class _GlyphChip extends StatelessWidget {
  const _GlyphChip({required this.icon, required this.size, this.color});

  final IconData icon;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tint == null
            ? DashboardColors.nested(context)
            : tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.29),
        border: Border.all(
          color: tint == null
              ? DashboardColors.border(context)
              : tint.withValues(alpha: 0.28),
        ),
      ),
      child: Icon(
        icon,
        size: size * 0.58,
        color: tint ?? DashboardColors.mutedInk(context),
      ),
    );
  }
}

/// The arrow-and-figure badge in a stacked tile's header — a 6px rect, not a
/// pill, matching every other status mark in the console.
class _TrendChip extends StatelessWidget {
  const _TrendChip({required this.trend});

  final KpiTrend trend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = trend._statusTone;
    final style = DashboardColors.status(context, tone);
    final line = DashboardColors.statusLine(context, tone);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: style.tint,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(trend.icon, size: 12, color: style.ink),
          const SizedBox(width: 2),
          // Ellipsised, not sized to its text: a movement phrase is as long as
          // the window it names («٢٣% عن الشهر السابق»), and on a narrow
          // console that is wider than the half-tile it shares with the label.
          Flexible(
            child: Text(
              trend.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: theme.textTheme.labelSmall?.copyWith(
                color: style.ink,
                fontWeight: FontWeight.w700,
              ),
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

  /// Tile height at the reader's default text size. It grows with the text
  /// scaler — see [_extentFor].
  final double itemExtent;

  final int maxColumns;

  const DashboardKpiGrid({
    super.key,
    required this.children,
    this.itemExtent = 88,
    this.maxColumns = 4,
  });

  /// A KPI tile is a fixed-height cell holding text that is not fixed height.
  /// At the console's declared 1.6× text scale the stacked tile's label, value
  /// and detail line together need more room than [itemExtent] gives, and a
  /// `GridView` cell does not grow to fit — the tile simply overflows and the
  /// detail line is cut off.
  ///
  /// So the cell grows with the reader instead. Only upward, and only as far as
  /// the scaler actually goes: at the default size this is exactly the extent
  /// the caller asked for.
  double _extentFor(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return scale <= 1 ? itemExtent : itemExtent * scale.clamp(1.0, 2.0);
  }

  @override
  Widget build(BuildContext context) {
    final extent = _extentFor(context);
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
            mainAxisExtent: extent,
          ),
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}
