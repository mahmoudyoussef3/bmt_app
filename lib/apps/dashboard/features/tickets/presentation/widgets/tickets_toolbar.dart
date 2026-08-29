import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_filter_bar.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_queue_tabs.dart';
import 'package:bmt_app/core/widgets/debounced_search_field.dart';

import '../../domain/entities/complaint.dart';
import '../cubit/tickets_cubit.dart';
import '../cubit/tickets_state.dart';
import '../models/ticket_queue_tab.dart';
import '../models/ticket_sort.dart';
import 'tickets_format.dart';

/// الشكاوى' toolbar — the shared [DashboardFilterBar], identical to the one
/// الحجوزات, الاشتراكات and العملاء wear: the queue strip, then the pinned
/// search and ordering, then the remaining narrowings behind one fold.
///
/// The module used to lay its own row out by hand — a search field beside two
/// dropdowns and a count chip — which is why the الدعم section read as a
/// different console from المبيعات one sidebar group above it. The controls are
/// the same set; only the shape changed.
class TicketsToolbar extends StatelessWidget {
  const TicketsToolbar({super.key, required this.state});

  final TicketsLoaded state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TicketsCubit>();

    return DashboardFilterBar(
      sectionId: DashboardSectionIds.ticketsFilters,
      tabs: DashboardQueueTabBar(
        tabs: [
          for (final tab in TicketQueueTab.values)
            DashboardQueueTab(
              label: tab.label,
              count: TicketsFormat.count(tab.countIn(state)),
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
        key: ValueKey('ticket-search-${state.searchQuery}'),
        initialValue: state.searchQuery,
        hintText: 'ابحث برقم التذكرة أو اسم العميل أو الهاتف أو العنوان',
        onChanged: cubit.setSearchQuery,
      ),
      // The direction toggle is offered here because both directions of every
      // key are real questions on a support desk: the soonest deadline and the
      // oldest complaint are each something an agent goes looking for.
      sort: DashboardSortControl<TicketSort>(
        value: state.sort,
        values: TicketSort.values,
        labelOf: (sort) => sort.label,
        onChanged: cubit.setSort,
        ascending: state.sortAscending,
        // `setSort` flips the direction when handed the key already in force,
        // which is exactly what the arrow means.
        onToggleDirection: () => cubit.setSort(state.sort),
      ),
      filters: _Filters(state: state, cubit: cubit),
      filterSummary: _summary(state),
      activeFilterCount: state.activeFilterCount,
      onClearFilters: cubit.clearFilters,
    );
  }

  /// What the folded filter row is still doing, in the agent's own words. A
  /// filter they have forgotten they set is how a narrowed queue gets read as
  /// the whole queue.
  static List<String> _summary(TicketsLoaded state) {
    if (state.activeFilterCount == 0) return const ['بدون تصفية'];
    return [
      if (state.searchQuery.trim().isNotEmpty)
        'بحث: ${state.searchQuery.trim()}',
      if (state.overdueOnly) 'المتأخرة فقط',
      if (state.filterStatus != null) 'الحالة: ${state.filterStatus!.label}',
      if (state.filterPriority != null)
        'الأولوية: ${state.filterPriority!.label}',
      if (state.filterCategory != null) 'الفئة: ${state.filterCategory}',
      if (state.filterAssignment != TicketAssignment.any)
        state.filterAssignment.label,
    ];
  }
}

/// The full set of narrowings, including the statuses the queue strip has no
/// room for — تم التواصل, مغلقة, مرفوضة — and the two axes that cut across
/// every queue: the priority and whether anyone has picked the ticket up.
class _Filters extends StatelessWidget {
  const _Filters({required this.state, required this.cubit});

  final TicketsLoaded state;
  final TicketsCubit cubit;

  @override
  Widget build(BuildContext context) {
    return DashboardFilterFields(
      fields: [
        DashboardFilterDropdown<TicketStatus?>(
          label: 'الحالة',
          icon: Icons.flag_outlined,
          value: state.filterStatus,
          values: const [null, ...TicketStatus.values],
          labelOf: (status) => status?.label ?? 'كل الحالات',
          onChanged: cubit.setFilterStatus,
        ),
        DashboardFilterDropdown<TicketPriority?>(
          label: 'الأولوية',
          icon: Icons.priority_high_rounded,
          value: state.filterPriority,
          values: const [null, ...TicketPriority.values],
          labelOf: (priority) => priority?.label ?? 'كل الأولويات',
          onChanged: cubit.setFilterPriority,
        ),
        DashboardFilterDropdown<String?>(
          label: 'الفئة',
          icon: Icons.sell_outlined,
          value: state.filterCategory,
          values: [null, ...state.categories],
          emptyHint: 'لا توجد فئات بعد',
          labelOf: (category) => category ?? 'كل الفئات',
          onChanged: cubit.setFilterCategory,
        ),
        DashboardFilterDropdown<TicketAssignment>(
          label: 'الإسناد',
          icon: Icons.person_search_outlined,
          value: state.filterAssignment,
          values: TicketAssignment.values,
          labelOf: (assignment) => assignment.label,
          onChanged: cubit.setFilterAssignment,
        ),
      ],
    );
  }
}
