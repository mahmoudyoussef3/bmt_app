import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';

/// One measured line inside a snapshot panel.
///
/// Deliberately quieter than [DashboardKpiCard]: the KPI strip at the top of
/// the page is the headline and earns its tint, and repeating that treatment
/// across another twenty figures would flatten the whole page into one loud
/// surface with no reading order. These are a well and a border — present,
/// scannable, and clearly secondary.
class OverviewMetric extends StatelessWidget {
  final String label;
  final String value;

  /// The context that makes the figure mean something — what it is out of,
  /// what window it covers.
  final String? hint;

  /// Tints the value only. Reserve it for figures that genuinely carry a
  /// verdict (an overdue count, money owed); an all-tinted grid says nothing.
  final Color? tone;

  /// Opens the module the figure came from.
  final VoidCallback? onTap;

  const OverviewMetric({
    super.key,
    required this.label,
    required this.value,
    this.hint,
    this.tone,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final radius = BorderRadius.circular(AppTokens.radiusSmall);

    final body = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.medium,
        vertical: AppSpacing.small,
      ),
      decoration: BoxDecoration(
        color: DashboardColors.well(context),
        borderRadius: radius,
        border: Border.all(color: DashboardColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
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
              if (onTap != null)
                Icon(
                  DashboardIcons.openModule,
                  size: 16,
                  color: scheme.onSurfaceVariant,
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: tone,
            ),
          ),
          if (hint != null)
            Text(
              hint!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );

    if (onTap == null) return body;
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(onTap: onTap, borderRadius: radius, child: body),
    );
  }
}

/// Responsive grid for [OverviewMetric]s — 4 / 3 / 2 / 1 columns by width.
///
/// One more step than [DashboardKpiGrid]'s 4/2/1: these tiles are narrower and
/// carry less text, so a laptop that fits two KPI tiles comfortably fits three
/// of these without either crowding.
class OverviewMetricGrid extends StatelessWidget {
  final List<Widget> children;
  final double itemExtent;

  const OverviewMetricGrid({
    super.key,
    required this.children,
    this.itemExtent = 78,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1000
            ? 4
            : width >= 720
            ? 3
            : width >= 420
            ? 2
            : 1;
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
