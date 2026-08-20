import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_empty_state.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_attention.dart';
import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

/// The Fleet module's own operational to-do list — every driver and vehicle
/// that [buildFleetAttentionItems] flagged, each with the one reason it was
/// flagged and a direct action to go fix it.
///
/// This sits one level below the Business Overview's "يحتاج قراراً منك"
/// section, which rolls the same underlying signals (expired documents,
/// vehicles in maintenance, ...) up into business-wide *categories*. Here,
/// already inside Fleet, the operator needs the opposite: which specific bus
/// or driver, not just how many.
class FleetNeedsAttentionPanel extends StatelessWidget {
  const FleetNeedsAttentionPanel({
    super.key,
    required this.items,
    required this.onOpenDriver,
    required this.onOpenVehicle,
  });

  final List<FleetAttentionItem> items;
  final ValueChanged<String> onOpenDriver;
  final ValueChanged<String> onOpenVehicle;

  static const int _maxVisible = 6;

  @override
  Widget build(BuildContext context) {
    final critical = items
        .where((i) => i.severity == FleetAttentionSeverity.critical)
        .length;
    final visible = items.take(_maxVisible).toList();
    final remaining = items.length - visible.length;

    return DashboardPanel(
      sectionId: DashboardSectionIds.fleetAttention,
      icon: items.isEmpty ? DashboardIcons.allClear : DashboardIcons.attention,
      title: 'يحتاج المتابعة',
      subtitle: items.isEmpty
          ? null
          : '${items.length} بند بانتظارك${critical > 0 ? ' · $critical حرج' : ''}',
      collapsedSummary: Text(
        items.isEmpty ? 'لا يوجد ما يحتاج المتابعة' : items.first.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      child: items.isEmpty
          ? const DashboardEmptyState(
              icon: DashboardIcons.allClear,
              title: 'الأسطول جاهز بالكامل',
              message: 'لا توجد مركبات أو سائقون يحتاجون متابعة الآن.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 1180
                        ? 3
                        : constraints.maxWidth >= 640
                        ? 2
                        : 1;
                    final gap = AppSpacing.small;
                    final cardWidth = columns == 1
                        ? constraints.maxWidth
                        : (constraints.maxWidth - gap * (columns - 1)) /
                              columns;

                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [
                        for (final item in visible)
                          SizedBox(
                            width: cardWidth,
                            child: _AttentionCard(
                              item: item,
                              onTap: () =>
                                  item.targetType == FleetAttentionTarget.driver
                                  ? onOpenDriver(item.targetId)
                                  : onOpenVehicle(item.targetId),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                if (remaining > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.small),
                    child: Text(
                      'و $remaining بند إضافي — افتح تبويب السائقين أو المركبات لعرض الكل',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

/// One flagged driver/vehicle, self-contained: identity, reason and action
/// all sit inside one bounded card instead of a full-width row.
///
/// The row this replaced put the action pill at the row's trailing edge —
/// fine at card width, but this panel spans the whole module width, so on a
/// desktop screen the pill ended up stranded ~800px away from the text it
/// belonged to, across a dead gap. Bounding each item to a grid cell keeps
/// what you're reading and what you'd tap next to each other regardless of
/// how wide the panel is.
class _AttentionCard extends StatelessWidget {
  const _AttentionCard({required this.item, required this.onTap});

  final FleetAttentionItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tone = item.severity == FleetAttentionSeverity.critical
        ? context.status(AppStatusTone.error)
        : context.status(AppStatusTone.warning);
    final radius = BorderRadius.circular(AppTokens.radiusSmall);
    final icon = item.targetType == FleetAttentionTarget.driver
        ? DashboardIcons.captain
        : DashboardIcons.vehicle;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.small),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: tone.tint, borderRadius: radius),
                child: Icon(icon, size: 18, color: tone.ink),
              ),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (item.subtitle.isNotEmpty)
                      Text(
                        item.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xSmall),
          Text(
            item.reason,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(color: tone.ink),
          ),
          const SizedBox(height: AppSpacing.small),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: tone.tint,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.actionLabel,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: tone.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        DashboardIcons.openModule,
                        size: 16,
                        color: tone.ink,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
