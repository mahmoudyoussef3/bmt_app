import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/routes/dashboard_routes.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_kpi_card.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';

import '../../domain/entities/dashboard_home_summary.dart';

/// Fleet health at a glance, from the same [FleetWorkspace] the Fleet module
/// itself loads — `documentsNeedFollowUpCount` doubles as the "needs
/// attention" signal the spec asks for, rather than inventing a new one.
class FleetSnapshotCard extends StatelessWidget {
  const FleetSnapshotCard({
    super.key,
    required this.summary,
    required this.onOpenModule,
  });

  final DashboardHomeSummary summary;
  final ValueChanged<String> onOpenModule;

  @override
  Widget build(BuildContext context) {
    final fleet = summary.fleetSummary;
    return DashboardPanel(
      icon: Icons.local_shipping_rounded,
      title: 'الأسطول',
      trailing: TextButton(
        onPressed: () => onOpenModule(DashboardRoutes.fleet),
        child: const Text('إدارة الأسطول'),
      ),
      child: DashboardKpiGrid(
        maxColumns: 3,
        itemExtent: 80,
        children: [
          DashboardKpiCard(
            label: 'إجمالي المركبات',
            value: '${fleet.vehiclesCount}',
            icon: Icons.local_shipping_outlined,
            color: const Color(0xFF0F2747),
          ),
          DashboardKpiCard(
            label: 'مركبات في مهام نشطة',
            value: '${fleet.activeAssignmentsCount}',
            icon: Icons.route_outlined,
            color: const Color(0xFF2F80ED),
          ),
          DashboardKpiCard(
            label: 'مستندات تحتاج متابعة',
            value: '${fleet.documentsNeedFollowUpCount}',
            icon: Icons.description_outlined,
            color: fleet.documentsNeedFollowUpCount > 0
                ? const Color(0xFFF5A623)
                : const Color(0xFF22A06B),
          ),
        ],
      ),
    );
  }
}
