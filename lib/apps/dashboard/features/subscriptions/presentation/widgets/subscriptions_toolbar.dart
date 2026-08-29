import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_filter_bar.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_queue_tabs.dart';
import 'package:bmt_app/core/widgets/debounced_search_field.dart';

import '../cubit/subscriptions_cubit.dart';
import '../cubit/subscriptions_state.dart';
import '../models/subscription_filters.dart';
import '../models/subscription_queue_tab.dart';
import '../models/subscription_sort.dart';
import 'subscription_formatting.dart';

/// الاشتراكات' toolbar — the shared [DashboardFilterBar], so it is the same
/// control الحجوزات and العملاء wear.
///
/// Search and ordering used to live *inside* the collapsed «التصفية» panel,
/// which is how a list ends up looking unsearchable and unsortable until you
/// discover the fold. They are pinned now, like everywhere else in المبيعات.
class SubscriptionsToolbar extends StatelessWidget {
  const SubscriptionsToolbar({super.key, required this.state});

  final SubscriptionsLoaded state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SubscriptionsCubit>();
    final filters = state.filters;

    return DashboardFilterBar(
      sectionId: DashboardSectionIds.subscriptionsFilters,
      tabs: DashboardQueueTabBar(
        tabs: [
          for (final tab in SubscriptionQueueTab.values)
            DashboardQueueTab(
              label: tab.label,
              count: arabicNumber(state.countForTab(tab)),
              selected: state.activeTab == tab,
              urgent: tab.isWorkQueue,
              onTap: () => cubit.switchTab(tab),
            ),
        ],
      ),
      search: DebouncedSearchField(
        key: ValueKey('subscription-search-${filters.search}'),
        initialValue: filters.search,
        hintText: 'ابحث بالاسم أو الهاتف أو الباقة أو خط السير',
        onChanged: (value) =>
            cubit.updateFilters(filters.copyWith(search: value)),
      ),
      // A trip in focus is ordered by the board's own rules — check-in state
      // first — so offering a sort there would be a control that does nothing.
      sort: state.tripBoard != null
          ? null
          : DashboardSortControl<SubscriptionSortField>(
              value: state.sortField,
              values: SubscriptionSortField.values,
              labelOf: (field) => field.label,
              onChanged: cubit.sortBy,
              ascending: state.sortAscending,
              // `sortBy` flips the direction when handed the field already in
              // force, which is exactly what the arrow means.
              onToggleDirection: () => cubit.sortBy(state.sortField),
            ),
      filters: _Filters(state: state, cubit: cubit),
      filterSummary: _summary(state),
      activeFilterCount: filters.activeCount,
      onClearFilters: cubit.clearFilters,
    );
  }

  /// Trip and route filters hold ids, so the summary resolves them back to the
  /// names the operator picked — an id in a chip would tell them nothing.
  static List<String> _summary(SubscriptionsLoaded state) {
    final filters = state.filters;
    if (!filters.isActive) return const ['بدون تصفية'];
    return [
      if (filters.search.trim().isNotEmpty) 'بحث: ${filters.search.trim()}',
      if (filters.tripId.isNotEmpty) 'رحلة محددة',
      if (filters.routeId.isNotEmpty) 'خط سير محدد',
      if (filters.packageName.isNotEmpty) 'باقة: ${filters.packageName}',
      if (filters.unpaidOnly) 'غير المسددين فقط',
    ];
  }
}

class _Filters extends StatelessWidget {
  const _Filters({required this.state, required this.cubit});

  final SubscriptionsLoaded state;
  final SubscriptionsCubit cubit;

  @override
  Widget build(BuildContext context) {
    final filters = state.filters;
    void update(SubscriptionFilters next) => cubit.updateFilters(next);

    final routes = state.availableRoutes.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    return DashboardFilterFields(
      fields: [
        // The trip picker — the filter this whole screen was rebuilt around.
        // Each option carries how many subscribers that departure has, so an
        // operator can find the trip worth opening without opening all of them.
        DashboardFilterDropdown<String?>(
          label: 'الرحلة',
          icon: Icons.directions_bus_filled_outlined,
          value: filters.tripId.isEmpty ? null : filters.tripId,
          values: [null, ...state.trips.map((trip) => trip.id)],
          emptyHint: 'لا توجد رحلات بعد',
          labelOf: (id) => id == null ? 'كل الرحلات' : _tripLabel(id),
          onChanged: cubit.selectTrip,
        ),
        DashboardFilterDropdown<String?>(
          label: 'خط السير',
          icon: Icons.alt_route_rounded,
          value: filters.routeId.isEmpty ? null : filters.routeId,
          values: [null, ...routes.map((entry) => entry.key)],
          emptyHint: 'لا توجد خطوط مرتبطة',
          labelOf: (id) =>
              id == null ? 'كل الخطوط' : (state.availableRoutes[id] ?? 'مسار'),
          // A trip already pins its own route; letting the two disagree is how
          // an empty board with no explanation happens.
          enabled: !filters.hasTrip,
          onChanged: (value) => update(filters.copyWith(routeId: value ?? '')),
        ),
        DashboardFilterDropdown<String?>(
          label: 'الباقة',
          icon: Icons.inventory_2_outlined,
          value: filters.packageName.isEmpty ? null : filters.packageName,
          values: [null, ...state.availablePackages],
          emptyHint: 'لا توجد باقات',
          labelOf: (name) => name ?? 'كل الباقات',
          onChanged: (value) =>
              update(filters.copyWith(packageName: value ?? '')),
        ),
      ],
      trailing: [
        FilterChip(
          selected: filters.unpaidOnly,
          onSelected: (value) => update(filters.copyWith(unpaidOnly: value)),
          avatar: const Icon(Icons.account_balance_wallet_outlined, size: 18),
          label: const Text('عليه مستحقات'),
        ),
      ],
    );
  }

  /// "TR-500 بنها ← القاهرة · ٣ مشتركين" — the count rides in the label rather
  /// than a badge widget, so the trip picker is the same dropdown as every
  /// other filter in المبيعات.
  String _tripLabel(String id) {
    final trip = state.trips.where((trip) => trip.id == id).firstOrNull;
    if (trip == null) return 'رحلة';
    final count = state.subscriberCountForTrip(trip);
    final label = arabicDigits(trip.label);
    return count == 0 ? label : '$label · ${arabicNumber(count)} مشترك';
  }
}
