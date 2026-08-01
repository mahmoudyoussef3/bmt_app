import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';
import 'package:bmt_app/apps/dashboard/features/notifications/presentation/cubit/operational_alerts_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/notifications/presentation/cubit/operational_alerts_state.dart';
import 'package:bmt_app/apps/dashboard/features/notifications/presentation/widgets/alert_tile.dart';
import 'package:bmt_app/core/widgets/empty_state.dart';

/// A chronological timeline of what actually happened, sourced from the same
/// trigger-populated `operational_alerts` feed as the bell icon — real events
/// (booking confirmed, payment approved, trip cancelled, …), not a
/// client-derived approximation.
class RecentActivitySection extends StatelessWidget {
  const RecentActivitySection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OperationalAlertsCubit, OperationalAlertsState>(
      builder: (context, state) {
        final items = switch (state) {
          OperationalAlertsLoaded(:final alerts) =>
            (List.of(alerts)
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt)))
                .take(8)
                .toList(),
          _ => const [],
        };

        return DashboardPanel(
          icon: Icons.history_rounded,
          title: 'أحدث النشاطات',
          child: switch (state) {
            OperationalAlertsError(:final message) => Text(
              message,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            _ when items.isEmpty => const EmptyState(
              emoji: '🕓',
              title: 'لا نشاط حتى الآن',
              subtitle: 'ستظهر هنا آخر الأحداث فور حدوثها.',
            ),
            _ => Column(
              children: [
                for (final alert in items)
                  AlertTile(
                    alert: alert,
                    onTap: () => context
                        .read<OperationalAlertsCubit>()
                        .markAsRead(alert.id),
                    onMarkRead: () => context
                        .read<OperationalAlertsCubit>()
                        .markAsRead(alert.id),
                  ),
              ],
            ),
          },
        );
      },
    );
  }
}
