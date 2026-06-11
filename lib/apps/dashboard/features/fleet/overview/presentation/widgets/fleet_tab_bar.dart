import 'package:flutter/material.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_common.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/theme/spacing.dart';

class FleetTabBar extends StatelessWidget {
  final FleetTab active;
  final ValueChanged<FleetTab> onTabChanged;

  const FleetTabBar({
    super.key,
    required this.active,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = FleetTab.values;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xSmall),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 720;

          final children = tabs.map((tab) {
            final selected = tab == active;
            return _DashboardTabButton(
              label: tab.label,
              selected: selected,
              onTap: () => onTabChanged(tab),
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
                        child: SizedBox(width: 132, child: child),
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

class _DashboardTabButton extends StatelessWidget {
  const _DashboardTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: selected ? scheme.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.medium,
            vertical: 12,
          ),
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: selected ? scheme.onPrimary : scheme.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
