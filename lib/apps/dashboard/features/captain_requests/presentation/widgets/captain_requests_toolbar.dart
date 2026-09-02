import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_filter_bar.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_queue_tabs.dart';
import 'package:bmt_app/core/widgets/debounced_search_field.dart';

import '../cubit/captain_requests_cubit.dart';
import '../cubit/captain_requests_state.dart';
import '../models/captain_request_queue_tab.dart';
import '../models/captain_request_sort.dart';
import 'captain_requests_format.dart';

/// طلبات الكباتن' toolbar — the shared [DashboardFilterBar] every list module
/// in this console wears: the queue strip, then the pinned search and ordering,
/// then the remaining narrowing behind one fold.
///
/// The module used to offer a two-segment «قيد المراجعة / الكل» switch in the
/// page header and no search at all, which is why الأسطول section read as a
/// different console from المبيعات one sidebar group above it.
class CaptainRequestsToolbar extends StatelessWidget {
  const CaptainRequestsToolbar({super.key, required this.state});

  final CaptainRequestsLoaded state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CaptainRequestsCubit>();

    return DashboardFilterBar(
      sectionId: DashboardSectionIds.captainRequestsFilters,
      tabs: DashboardQueueTabBar(
        tabs: [
          for (final tab in CaptainRequestQueueTab.values)
            DashboardQueueTab(
              label: tab.label,
              count: CaptainRequestsFormat.count(tab.countIn(state)),
              selected: tab.isSelectedBy(state),
              urgent: tab.isWorkQueue,
              onTap: () => cubit.switchTab(tab),
            ),
        ],
      ),
      search: DebouncedSearchField(
        // Keyed on the term so clearing the filters from anywhere else — the
        // reset button, the empty state — resets the field rather than leaving
        // stale text above an unfiltered queue.
        key: ValueKey('captain-request-search-${state.searchQuery}'),
        initialValue: state.searchQuery,
        hintText: 'ابحث باسم السائق أو رقم الهاتف أو نص الطلب',
        onChanged: cubit.setSearchQuery,
      ),
      // Both directions of every key are real questions here: the newest
      // arrival and the request that has been waiting longest are each
      // something an operator goes looking for.
      sort: DashboardSortControl<CaptainRequestSort>(
        value: state.sort,
        values: CaptainRequestSort.values,
        labelOf: (sort) => sort.label,
        onChanged: cubit.setSort,
        ascending: state.sortAscending,
        // `setSort` flips the direction when handed the key already in force,
        // which is exactly what the arrow means.
        onToggleDirection: () => cubit.setSort(state.sort),
      ),
      filters: DashboardFilterFields(
        fields: [
          DashboardFilterDropdown<CaptainRequestWindow>(
            label: 'فترة الطلب',
            icon: Icons.event_outlined,
            value: state.filterWindow,
            values: CaptainRequestWindow.values,
            labelOf: (window) => window.label,
            onChanged: cubit.setFilterWindow,
          ),
        ],
      ),
      filterSummary: _summary(state),
      activeFilterCount: state.activeFilterCount,
      onClearFilters: cubit.clearFilters,
    );
  }

  /// What the folded filter row is still doing, in the operator's own words. A
  /// filter they have forgotten they set is how a narrowed queue gets read as
  /// the whole queue.
  static List<String> _summary(CaptainRequestsLoaded state) {
    if (state.activeFilterCount == 0) return const ['بدون تصفية'];
    return [
      if (state.searchQuery.trim().isNotEmpty)
        'بحث: ${state.searchQuery.trim()}',
      if (state.filterWindow != CaptainRequestWindow.all)
        state.filterWindow.label,
    ];
  }
}
