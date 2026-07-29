import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';

/// Unified KPI / stat tile used across every dashboard module.
///
/// A tinted, bordered tile with an icon, a label, an optional [detail] line
/// and a prominent [value]. Pair with [DashboardKpiGrid] for a responsive row
/// of stats. Replaces the per-module tiles that previously diverged in
/// padding, color and typography.
class DashboardKpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String? detail;
  final IconData icon;
  final Color? color;

  const DashboardKpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.detail,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = color ?? scheme.primary;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: tint.withAlpha(16),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: tint.withAlpha(45)),
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
