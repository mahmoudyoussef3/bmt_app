import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_filter_bar.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_queue_tabs.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/overview/presentation/widgets/fleet_format.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_workspace.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/presentation/models/fleet_queue.dart';
import 'package:bmt_app/core/widgets/debounced_search_field.dart';

/// The orderings المركبات is read in — one key per sortable column header, so
/// the pinned control and the headers drive a single value.
enum FleetVehicleSort {
  code('كود المركبة'),
  modelYear('سنة الموديل'),
  seats('عدد المقاعد'),
  status('حالة السجل');

  const FleetVehicleSort(this.label);

  final String label;
}

/// المركبات' toolbar — the shared [DashboardFilterBar] every list module in
/// this console wears: the queue strip, then the pinned search and ordering,
/// then the remaining narrowing behind one fold.
///
/// This module used to lay its own row out by hand — a search field beside a
/// horizontally scrolling `ChoiceChip` bar and a `MenuAnchor` sort — rendered
/// inside the table's own card. Same controls, one shape.
class FleetVehiclesToolbar extends StatelessWidget {
  const FleetVehiclesToolbar({
    super.key,
    required this.vehicles,
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

  /// The whole (unfiltered) list, so each pill can carry its own real count.
  final List<FleetVehicle> vehicles;
  final FleetWorkspace workspace;

  final FleetVehicleQueue queue;
  final FleetVehicleStatus? recordStatus;
  final String searchQuery;
  final FleetVehicleSort sort;
  final bool sortAscending;

  final ValueChanged<FleetVehicleQueue> onQueueChanged;
  final ValueChanged<FleetVehicleStatus?> onRecordStatusChanged;
  final ValueChanged<String> onSearch;
  final ValueChanged<FleetVehicleSort> onSort;
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
      sectionId: DashboardSectionIds.fleetVehicleFilters,
      tabs: DashboardQueueTabBar(
        tabs: [
          for (final tab in FleetVehicleQueue.values)
            DashboardQueueTab(
              label: tab.label,
              count: FleetFormat.count(tab.countIn(vehicles, workspace)),
              selected: tab == queue,
              urgent: tab.isWorkQueue,
              onTap: () => onQueueChanged(tab),
            ),
        ],
      ),
      search: DebouncedSearchField(
        // Keyed on the term so clearing the filters from anywhere else — the
        // reset button, the empty state — resets the field rather than leaving
        // stale text above an unfiltered list.
        key: ValueKey('fleet-vehicle-search-$searchQuery'),
        initialValue: searchQuery,
        hintText: 'ابحث برقم المركبة أو رقم اللوحة أو الموديل',
        onChanged: onSearch,
      ),
      sort: DashboardSortControl<FleetVehicleSort>(
        value: sort,
        values: FleetVehicleSort.values,
        labelOf: (value) => value.label,
        onChanged: onSort,
        ascending: sortAscending,
        // `onSort` flips the direction when handed the key already in force,
        // which is exactly what the arrow means.
        onToggleDirection: () => onSort(sort),
      ),
      filters: DashboardFilterFields(
        // The record axis, which the pill strip deliberately leaves out: the
        // strip answers what a bus is *doing*, this answers what state its
        // record is in, and the two can legitimately disagree.
        fields: [
          DashboardFilterDropdown<FleetVehicleStatus?>(
            label: 'حالة السجل',
            icon: Icons.flag_outlined,
            value: recordStatus,
            values: const [null, ...FleetVehicleStatus.values],
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
