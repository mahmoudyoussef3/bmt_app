import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_filter_bar.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_queue_tabs.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/overview/presentation/widgets/fleet_format.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_workspace.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/presentation/models/fleet_queue.dart';
import 'package:bmt_app/core/widgets/debounced_search_field.dart';

/// The orderings السائقون is read in — one key per sortable column header, so
/// the pinned control and the headers drive a single value.
enum FleetDriverSort {
  name('اسم السائق'),
  licenseExpiry('انتهاء الرخصة');

  const FleetDriverSort(this.label);

  final String label;
}

/// السائقون' toolbar — [FleetVehiclesToolbar]'s twin one tab over, on the same
/// shared [DashboardFilterBar]. The two halves of الأسطول must offer the same
/// controls in the same places; only the queues and the record enum differ.
class FleetDriversToolbar extends StatelessWidget {
  const FleetDriversToolbar({
    super.key,
    required this.drivers,
    required this.workspace,
    required this.queue,
    required this.recordStatus,
    required this.searchQuery,
    required this.sort,
    required this.sortAscending,
    required this.onQueueChanged,
    required this.onRecordStatusChanged,
    required this.onSearch,
    required this.onSort,
    required this.onClearFilters,
    required this.selectedCount,
    required this.onSuspendSelected,
  });

  /// The whole (unfiltered) roster, so each pill can carry its own real count.
  final List<FleetDriver> drivers;
  final FleetWorkspace workspace;

  final FleetDriverQueue queue;
  final FleetDriverStatus? recordStatus;
  final String searchQuery;
  final FleetDriverSort sort;
  final bool sortAscending;

  final ValueChanged<FleetDriverQueue> onQueueChanged;
  final ValueChanged<FleetDriverStatus?> onRecordStatusChanged;
  final ValueChanged<String> onSearch;
  final ValueChanged<FleetDriverSort> onSort;
  final VoidCallback onClearFilters;

  final int selectedCount;
  final VoidCallback? onSuspendSelected;

  int get _activeFilterCount =>
      (searchQuery.trim().isEmpty ? 0 : 1) + (recordStatus == null ? 0 : 1);

  List<String> get _filterSummary {
    if (_activeFilterCount == 0) return const ['بدون تصفية'];
    return [
      if (searchQuery.trim().isNotEmpty) 'بحث: ${searchQuery.trim()}',
      if (recordStatus != null) 'حالة السجل: ${recordStatus!.label}',
    ];
  }

  @override
  Widget build(BuildContext context) {
    return DashboardFilterBar(
      sectionId: DashboardSectionIds.fleetDriverFilters,
      tabs: DashboardQueueTabBar(
        tabs: [
          for (final tab in FleetDriverQueue.values)
            DashboardQueueTab(
              label: tab.label,
              count: FleetFormat.count(tab.countIn(drivers, workspace)),
              selected: tab == queue,
              urgent: tab.isWorkQueue,
              onTap: () => onQueueChanged(tab),
            ),
        ],
      ),
      search: DebouncedSearchField(
        key: ValueKey('fleet-driver-search-$searchQuery'),
        initialValue: searchQuery,
        hintText: 'ابحث باسم السائق أو الكود الوظيفي أو رقم الهاتف',
        onChanged: onSearch,
      ),
      sort: DashboardSortControl<FleetDriverSort>(
        value: sort,
        values: FleetDriverSort.values,
        labelOf: (value) => value.label,
        onChanged: onSort,
        ascending: sortAscending,
        onToggleDirection: () => onSort(sort),
      ),
      filters: DashboardFilterFields(
        // The record axis, which the pill strip deliberately leaves out: the
        // strip answers whether a driver can be put on a bus today, this
        // answers what state their file is in.
        fields: [
          DashboardFilterDropdown<FleetDriverStatus?>(
            label: 'حالة السجل',
            icon: Icons.flag_outlined,
            value: recordStatus,
            values: const [null, ...FleetDriverStatus.values],
            labelOf: (status) => status?.label ?? 'كل السجلات',
            onChanged: onRecordStatusChanged,
          ),
        ],
        trailing: [
          if (selectedCount > 0)
            FilledButton.tonalIcon(
              onPressed: onSuspendSelected,
              icon: const Icon(Icons.pause_circle_outline_rounded),
              label: Text('إيقاف ${FleetFormat.count(selectedCount)}'),
            ),
        ],
      ),
      filterSummary: _filterSummary,
      activeFilterCount: _activeFilterCount,
      onClearFilters: onClearFilters,
    );
  }
}
