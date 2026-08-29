import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_filter_bar.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_queue_tabs.dart';
import 'package:bmt_app/core/widgets/debounced_search_field.dart';

import '../../domain/entities/customer_filters.dart';
import '../cubit/customers_cubit.dart';
import '../cubit/customers_state.dart';
import '../models/customer_queue_tab.dart';
import 'customers_format.dart';

/// العملاء' toolbar — the shared [DashboardFilterBar], identical to the one
/// الحجوزات and الاشتراكات wear: the slice strip, then the pinned search and
/// ordering, then the remaining filters behind one fold.
class CustomersToolbar extends StatelessWidget {
  const CustomersToolbar({super.key, required this.state});

  final CustomersLoadedState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CustomersCubit>();
    final filters = state.filters;

    return DashboardFilterBar(
      sectionId: DashboardSectionIds.customersFilters,
      tabs: DashboardQueueTabBar(
        tabs: [
          for (final tab in CustomerQueueTab.values)
            DashboardQueueTab(
              label: tab.label,
              count: CustomersFormat.count(tab.countIn(state.overview)),
              selected: tab.isSelectedBy(filters),
              onTap: () => cubit.applyFilters(tab.applyTo(filters)),
            ),
        ],
      ),
      search: DebouncedSearchField(
        // Keyed on the term so clearing the filters from anywhere else — a KPI
        // tile, the reset button — resets the field rather than leaving stale
        // text above an unfiltered list.
        key: ValueKey('customer-search-${filters.search}'),
        initialValue: filters.search,
        hintText: 'ابحث بالاسم أو رقم الهاتف أو البريد أو رقم العميل',
        onChanged: cubit.search,
      ),
      // No direction toggle: each key here has one sensible direction — newest
      // activity first, most bookings first, soonest trip first, names A→Z —
      // and the server applies it. "The customer who has spent least" would be
      // a control nobody uses standing in front of one everybody does.
      sort: DashboardSortControl<CustomerSort>(
        value: filters.sort,
        values: CustomerSort.values,
        labelOf: (sort) => sort.label,
        onChanged: cubit.setSort,
      ),
      filters: _Filters(state: state, cubit: cubit),
      filterSummary: _summary(filters),
      activeFilterCount: filters.activeCount,
      onClearFilters: cubit.clearFilters,
    );
  }

  /// What the folded filter row is still doing, in the operator's own words.
  static List<String> _summary(CustomerFilters filters) {
    if (filters.activeCount == 0) return const ['بدون تصفية'];
    final status = filters.status;
    return [
      if (filters.search.trim().isNotEmpty) 'بحث: ${filters.search.trim()}',
      if (filters.subscription != CustomerSubscriptionFilter.any)
        filters.subscription.label,
      if (filters.upcoming != CustomerUpcomingFilter.any)
        filters.upcoming.label,
      if (filters.activity != CustomerActivityFilter.any)
        filters.activity.label,
      if (status != null) 'الحالة: ${CustomersFormat.clientStatus(status)}',
    ];
  }
}

/// The full set of narrowings, including the "none" halves the tab strip has no
/// room for — customers *without* a subscription, *without* an upcoming trip,
/// dormant for ninety days.
class _Filters extends StatelessWidget {
  const _Filters({required this.state, required this.cubit});

  final CustomersLoadedState state;
  final CustomersCubit cubit;

  @override
  Widget build(BuildContext context) {
    final filters = state.filters;

    return DashboardFilterFields(
      fields: [
        DashboardFilterDropdown<CustomerSubscriptionFilter>(
          label: 'الاشتراك',
          icon: Icons.workspace_premium_outlined,
          value: filters.subscription,
          values: CustomerSubscriptionFilter.values,
          labelOf: (value) => value.label,
          onChanged: cubit.setSubscriptionFilter,
        ),
        DashboardFilterDropdown<CustomerUpcomingFilter>(
          label: 'الرحلات القادمة',
          icon: Icons.event_available_outlined,
          value: filters.upcoming,
          values: CustomerUpcomingFilter.values,
          labelOf: (value) => value.label,
          onChanged: cubit.setUpcomingFilter,
        ),
        DashboardFilterDropdown<CustomerActivityFilter>(
          label: 'النشاط',
          icon: Icons.timeline_rounded,
          value: filters.activity,
          values: CustomerActivityFilter.values,
          labelOf: (value) => value.label,
          onChanged: cubit.setActivityFilter,
        ),
        DashboardFilterDropdown<String?>(
          label: 'حالة الحساب',
          icon: Icons.badge_outlined,
          value: filters.status,
          // `clients.status` is the passenger's own account state and the
          // office does not own it, so the options mirror the database rather
          // than being invented here.
          values: const [null, 'active', 'suspended', 'blocked'],
          labelOf: (value) =>
              value == null ? 'الكل' : CustomersFormat.clientStatus(value),
          onChanged: cubit.setStatusFilter,
        ),
      ],
    );
  }
}
