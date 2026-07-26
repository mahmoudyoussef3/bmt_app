import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/routes/dashboard_routes.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_kpi_card.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';

import '../../domain/entities/dashboard_home_summary.dart';

/// Driver headcount plus the one thing that's actually actionable here: new
/// join requests waiting on a decision.
class CaptainsSnapshotCard extends StatelessWidget {
  const CaptainsSnapshotCard({
    super.key,
    required this.summary,
    required this.onOpenModule,
  });

  final DashboardHomeSummary summary;
  final ValueChanged<String> onOpenModule;

  @override
  Widget build(BuildContext context) {
    final fleet = summary.fleetSummary;
    final pending = summary.pendingCaptainRequestsCount;
    return DashboardPanel(
      icon: Icons.how_to_reg_rounded,
      title: 'السائقون',
      trailing: pending > 0
          ? FilledButton.tonal(
              onPressed: () => onOpenModule(DashboardRoutes.captainRequests),
              child: const Text('مراجعة طلبات السائقين'),
            )
          : null,
      child: DashboardKpiGrid(
        maxColumns: 3,
        itemExtent: 80,
        children: [
          DashboardKpiCard(
            label: 'إجمالي السائقين',
            value: '${fleet.driversCount}',
            icon: Icons.badge_outlined,
            color: const Color(0xFF0F2747),
          ),
          DashboardKpiCard(
            label: 'سائقون في مهام نشطة',
            value: '${fleet.activeAssignmentsCount}',
            icon: Icons.directions_car_filled_outlined,
            color: const Color(0xFF2F80ED),
          ),
          DashboardKpiCard(
            label: 'طلبات انضمام جديدة',
            value: '$pending',
            icon: Icons.person_add_alt_1_rounded,
            color: pending > 0
                ? const Color(0xFFF5A623)
                : const Color(0xFF22A06B),
          ),
        ],
      ),
    );
  }
}
