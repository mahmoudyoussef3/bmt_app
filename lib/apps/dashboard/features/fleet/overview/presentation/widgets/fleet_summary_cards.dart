import 'package:flutter/material.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_workspace.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/theme/spacing.dart';

class FleetSummaryCards extends StatelessWidget {
  final FleetSummary summary;

  const FleetSummaryCards({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final items = [
      _SummaryItem(
        title: 'السائقين',
        value: '${summary.driversCount}',
        subtitle: 'إجمالي المسجلين',
        icon: Icons.badge_outlined,
      ),
      _SummaryItem(
        title: 'المركبات',
        value: '${summary.vehiclesCount}',
        subtitle: 'جاهزة أو تحت المتابعة',
        icon: Icons.directions_bus_outlined,
      ),
      _SummaryItem(
        title: 'التعيينات',
        value: '${summary.activeAssignmentsCount}',
        subtitle: 'تعيينات نشطة الآن',
        icon: Icons.link_rounded,
      ),
      _SummaryItem(
        title: 'الوثائق',
        value: '${summary.documentsNeedFollowUpCount}',
        subtitle: 'تحتاج مراجعة',
        icon: Icons.fact_check_outlined,
        highlight: summary.documentsNeedFollowUpCount > 0,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1100
            ? 4
            : width >= 720
                ? 2
                : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: AppSpacing.medium,
            mainAxisSpacing: AppSpacing.medium,
            mainAxisExtent: 118,
          ),
          itemBuilder: (context, index) => _SummaryCard(item: items[index]),
        );
      },
    );
  }
}

class _SummaryItem {
  const _SummaryItem({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    this.highlight = false,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final bool highlight;
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.item});

  final _SummaryItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = item.highlight ? scheme.error : scheme.primary;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withAlpha(18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(item.icon, color: color, size: 28),
          ),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
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
          Text(
            item.value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}
