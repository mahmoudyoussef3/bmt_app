import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';

/// One part of a whole, in a [DashboardStackedBar].
class DashboardBarSegment {
  const DashboardBarSegment({
    required this.label,
    required this.value,
    required this.color,
    this.valueLabel,
    this.onTap,
  });

  final String label;

  /// The share this segment takes of the bar. Negative values are treated as
  /// zero — a stacked bar has no room below the axis.
  final double value;

  final Color color;

  /// How the figure is written in the legend and the tooltip — «١٢ رحلة»,
  /// «1,800 ج.م». Defaults to the rounded number.
  final String? valueLabel;

  final VoidCallback? onTap;

  String get _reading => valueLabel ?? value.round().toString();
}

/// One measurement split several ways, drawn as a single bar with a legend.
///
/// The console reaches for this whenever a set of counts are **parts of one
/// total** rather than unrelated readings: the day's trips by status, a
/// collected amount by what it was spent on, a fleet by where its buses are. A
/// row of separate tiles says the opposite — four measurements, no relationship
/// — and it cannot answer the question the bar answers for free: *how much of
/// the whole is this?*
///
/// Three rules the drawing keeps:
///
/// * **A measured segment is always visible.** Flexing purely by value makes a
///   1% slice a sub-pixel sliver that paints nothing, so a reader sees «550
///   ج.م refunded» in the legend and an unbroken bar above it. Every non-zero
///   segment gets at least [_minShare] of the width, and the rest of the bar is
///   shared out proportionally from what is left.
/// * **Zero is not drawn, but it is still stated.** A segment with no value
///   leaves the bar and keeps its legend entry, greyed — "none cancelled" is an
///   answer, and a legend that changes length as the day goes on is unreadable.
/// * **An empty total is a well, not a blank.** With nothing measured the bar
///   draws the recessed track, so the panel reads as "nothing yet" rather than
///   as a widget that failed to render.
class DashboardStackedBar extends StatelessWidget {
  const DashboardStackedBar({
    super.key,
    required this.segments,
    this.title,
    this.trailingNote,
    this.height = 10,
    this.showLegend = true,
  });

  final List<DashboardBarSegment> segments;

  /// The name of the whole — «رحلات اليوم», «تركيبة المحصّل».
  final String? title;

  /// The total, or whatever qualifies it, at the end of the title line.
  final String? trailingNote;

  final double height;

  final bool showLegend;

  /// The floor a non-zero segment is guaranteed. 2.5% of the bar is roughly
  /// 8px on a panel-width card — enough to read as a band of colour.
  static const double _minShare = 0.025;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final drawn = segments.where((s) => s.value > 0).toList();
    final total = drawn.fold<double>(0, (sum, s) => sum + s.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  title!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (trailingNote != null)
                Text(
                  trailingNote!,
                  style: text.labelSmall?.copyWith(
                    color: DashboardColors.mutedInk(context),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: height,
            child: drawn.isEmpty || total <= 0
                ? ColoredBox(color: DashboardColors.well(context))
                : Row(
                    // Stretch, not the default centre: an `Expanded`
                    // `ColoredBox` gets loose vertical constraints under
                    // `CrossAxisAlignment.center` and paints nothing at all —
                    // the bar becomes a band of empty space.
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final segment in drawn)
                        Expanded(
                          flex: _flexFor(segment, drawn, total),
                          child: Tooltip(
                            message: '${segment.label} ${segment._reading}',
                            child: segment.onTap == null
                                ? ColoredBox(color: segment.color)
                                : InkWell(
                                    onTap: segment.onTap,
                                    child: ColoredBox(color: segment.color),
                                  ),
                          ),
                        ),
                    ],
                  ),
          ),
        ),
        if (showLegend) ...[
          const SizedBox(height: AppSpacing.small),
          Wrap(
            spacing: AppSpacing.medium,
            runSpacing: AppSpacing.xSmall,
            children: [
              for (final segment in segments) _Legend(segment: segment),
            ],
          ),
        ],
      ],
    );
  }

  /// Integer flex weights over 1000, with every drawn segment floored at
  /// [_minShare] and the remainder split by true proportion.
  static int _flexFor(
    DashboardBarSegment segment,
    List<DashboardBarSegment> drawn,
    double total,
  ) {
    final floor = _minShare;
    final headroom = 1 - floor * drawn.length;
    final share = headroom <= 0
        ? 1 / drawn.length
        : floor + (segment.value / total) * headroom;
    return (share * 1000).round().clamp(1, 1000);
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.segment});

  final DashboardBarSegment segment;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final empty = segment.value <= 0;

    final body = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: empty
                  ? DashboardColors.borderStrong(context)
                  : segment.color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${segment.label} ${segment._reading}',
            style: text.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: empty
                  ? DashboardColors.faintInk(context)
                  : DashboardColors.mutedInk(context),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );

    if (segment.onTap == null) return body;
    return InkWell(
      onTap: segment.onTap,
      borderRadius: BorderRadius.circular(6),
      child: body,
    );
  }
}
