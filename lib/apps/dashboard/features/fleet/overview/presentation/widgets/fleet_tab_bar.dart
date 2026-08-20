import 'package:flutter/material.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_workspace.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';

class FleetTabBar extends StatelessWidget {
  final FleetTab active;
  final FleetSummary summary;
  final ValueChanged<FleetTab> onTabChanged;

  const FleetTabBar({
    super.key,
    required this.active,
    required this.summary,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _FleetNavItem(
        tab: FleetTab.drivers,
        icon: Icons.badge_outlined,
        count: summary.driversCount,
        subtitle: 'بيانات وجاهزية السائقين',
      ),
      _FleetNavItem(
        tab: FleetTab.vehicles,
        icon: Icons.directions_bus_outlined,
        count: summary.vehiclesCount,
        subtitle: 'حالة المركبات والتراخيص',
      ),
    ];

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.small),
      child: LayoutBuilder(
        builder: (context, constraints) {
          
          const minTabWidth = 224.0;
          final isCompact = constraints.maxWidth < minTabWidth * tabs.length;

          final children = tabs.map((tab) {
            final selected = tab.tab == active;
            return _DashboardTabButton(
              item: tab,
              selected: selected,
              onTap: () => onTabChanged(tab.tab),
            );
          }).toList();

          if (isCompact) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: children
                    .map(
                      (child) => Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: SizedBox(width: minTabWidth, child: child),
                      ),
                    )
                    .toList(),
              ),
            );
          }

          return Row(
            children: children
                .map(
                  (child) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: child,
                    ),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}

class _FleetNavItem {
  const _FleetNavItem({
    required this.tab,
    required this.icon,
    required this.count,
    required this.subtitle,
  });

  final FleetTab tab;
  final IconData icon;
  final int count;
  final String subtitle;
}

class _DashboardTabButton extends StatelessWidget {
  const _DashboardTabButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _FleetNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = scheme.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: selected ? color.withAlpha(22) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(
          color: selected ? color.withAlpha(120) : scheme.outline.withAlpha(60),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTokens.radius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.small,
            vertical: 12,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selected
                      ? color.withAlpha(26)
                      : scheme.surfaceContainerHighest.withAlpha(90),
                  borderRadius: BorderRadius.circular(AppTokens.radius),
                ),
                child: Icon(item.icon, color: color, size: 22),
              ),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.tab.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xSmall),
              Text(
                '${item.count}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
