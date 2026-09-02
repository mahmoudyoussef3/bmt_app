import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_queue_tabs.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_workspace.dart';

import 'fleet_format.dart';

/// The switch between الأسطول' two halves — the roster and the buses.
///
/// The same [DashboardQueueTabBar] pill strip every list module in this console
/// uses for its queues, rather than the pair of tall bordered nav cards this
/// used to draw. It is not a *queue* strip — drivers and vehicles are two
/// entity types, not two predicates over one list — but it is the same
/// *control*, and the module below it opens its own queue strip a few pixels
/// down: two different-looking tab controls stacked on one screen is what made
/// this module read as its own console.
class FleetTabBar extends StatelessWidget {
  const FleetTabBar({
    super.key,
    required this.active,
    required this.summary,
    required this.onTabChanged,
  });

  final FleetTab active;
  final FleetSummary summary;
  final ValueChanged<FleetTab> onTabChanged;

  int _countFor(FleetTab tab) => switch (tab) {
    FleetTab.drivers => summary.driversCount,
    FleetTab.vehicles => summary.vehiclesCount,
  };

  @override
  Widget build(BuildContext context) {
    return DashboardQueueTabBar(
      tabs: [
        for (final tab in FleetTab.values)
          DashboardQueueTab(
            label: tab.label,
            count: FleetFormat.count(_countFor(tab)),
            selected: tab == active,
            onTap: () => onTabChanged(tab),
          ),
      ],
    );
  }
}
