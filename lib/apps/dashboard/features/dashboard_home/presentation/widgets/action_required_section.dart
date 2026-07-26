import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/routes/dashboard_routes.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';
import 'package:bmt_app/apps/dashboard/features/notifications/domain/entities/operational_alert.dart';
import 'package:bmt_app/apps/dashboard/features/notifications/presentation/cubit/operational_alerts_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/notifications/presentation/cubit/operational_alerts_state.dart';
import 'package:bmt_app/apps/dashboard/features/notifications/presentation/widgets/alert_tile.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/empty_state.dart';

/// "What should the office operator do right now?" — unread operational
/// alerts only, grouped by priority. Reads [OperationalAlertsCubit] directly
/// rather than folding alerts into [DashboardHomeCubit]: the cubit already
/// exists, already powers the shell's bell badge, and is trigger-driven real
/// data, so mounting it here is reuse, not a new data path.
class ActionRequiredSection extends StatelessWidget {
  const ActionRequiredSection({super.key, required this.onOpenModule});

  final ValueChanged<String> onOpenModule;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OperationalAlertsCubit, OperationalAlertsState>(
      builder: (context, state) {
        final items = switch (state) {
          OperationalAlertsLoaded(:final alerts) =>
            alerts.where((a) => !a.isRead).toList()
              ..sort((a, b) => b.priority.index.compareTo(a.priority.index)),
          _ => const <OperationalAlert>[],
        };

        return DashboardPanel(
          icon: Icons.notification_important_rounded,
          title: 'يحتاج إلى انتباهك',
          subtitle: items.isEmpty ? null : '${items.length} عنصر بحاجة لمتابعة',
          child: switch (state) {
            OperationalAlertsError(:final message) => Text(
              message,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            _ when items.isEmpty => const EmptyState(
              emoji: '✅',
              title: 'لا توجد إجراءات عاجلة',
              subtitle: 'كل شيء تحت السيطرة حالياً.',
            ),
            _ => Column(
              children: [
                for (final tier in _tiers)
                  _TierGroup(
                    label: tier.label,
                    items: items
                        .where((a) => tier.priorities.contains(a.priority))
                        .toList(),
                    onOpenModule: onOpenModule,
                  ),
              ],
            ),
          },
        );
      },
    );
  }
}

class _Tier {
  final String label;
  final List<OperationalAlertPriority> priorities;
  const _Tier(this.label, this.priorities);
}

const _tiers = [
  _Tier('عاجل', [OperationalAlertPriority.urgent]),
  _Tier('مهم', [OperationalAlertPriority.high]),
  _Tier('متابعة', [
    OperationalAlertPriority.normal,
    OperationalAlertPriority.low,
  ]),
];

class _TierGroup extends StatelessWidget {
  const _TierGroup({
    required this.label,
    required this.items,
    required this.onOpenModule,
  });

  final String label;
  final List<OperationalAlert> items;
  final ValueChanged<String> onOpenModule;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.small),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.small,
              vertical: AppSpacing.xSmall,
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ),
          for (final alert in items)
            AlertTile(
              alert: alert,
              onTap: () {
                context.read<OperationalAlertsCubit>().markAsRead(alert.id);
                final route = _routeFor(alert.type);
                if (route != null) onOpenModule(route);
              },
              onMarkRead: () =>
                  context.read<OperationalAlertsCubit>().markAsRead(alert.id),
            ),
        ],
      ),
    );
  }

  String? _routeFor(OperationalAlertType type) => switch (type) {
    OperationalAlertType.paymentReview => DashboardRoutes.paymentVerification,
    OperationalAlertType.captainRequest => DashboardRoutes.captainRequests,
    OperationalAlertType.supportTicket => DashboardRoutes.tickets,
    OperationalAlertType.refundRequest => DashboardRoutes.payments,
    OperationalAlertType.tripCancelled => DashboardRoutes.trips,
    OperationalAlertType.general => null,
  };
}
