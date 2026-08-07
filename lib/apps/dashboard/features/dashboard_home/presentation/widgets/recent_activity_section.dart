import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/routes/dashboard_routes.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_empty_state.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';
import 'package:bmt_app/apps/dashboard/features/notifications/presentation/cubit/operational_alerts_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/notifications/presentation/cubit/operational_alerts_state.dart';
import 'package:bmt_app/apps/dashboard/features/notifications/presentation/widgets/alert_tile.dart';

/// A chronological timeline of what actually happened, sourced from the same
/// trigger-populated `operational_alerts` feed as the bell icon — real events
/// (booking confirmed, payment approved, trip cancelled, …), not a
/// client-derived approximation.
///
/// Five rows, not eight: this answers "anything happen while I was away?", and
/// the answer past five rows is "open the notifications centre".
class RecentActivitySection extends StatelessWidget {
  const RecentActivitySection({super.key, this.onOpenModule, this.limit = 5});

  final ValueChanged<String>? onOpenModule;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final open = onOpenModule;

    return BlocBuilder<OperationalAlertsCubit, OperationalAlertsState>(
      builder: (context, state) {
        final items = switch (state) {
          OperationalAlertsLoaded(:final alerts) =>
            (List.of(alerts)
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt)))
                .take(limit)
                .toList(),
          _ => const [],
        };

        return DashboardPanel(
          sectionId: DashboardSectionIds.homeRecentActivity,
          icon: DashboardIcons.activity,
          title: 'أحدث النشاطات',
          trailing: open == null
              ? null
              : TextButton(
                  onPressed: () => open(DashboardRoutes.notifications),
                  child: const Text('عرض الكل'),
                ),
          child: switch (state) {
            OperationalAlertsError(:final message) => Text(
              message,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            _ when items.isEmpty => const DashboardEmptyState(
              icon: DashboardIcons.activity,
              title: 'لا نشاط حتى الآن',
              message: 'ستظهر هنا آخر الأحداث فور حدوثها.',
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
