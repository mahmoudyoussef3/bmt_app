import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_filter_bar.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_queue_tabs.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/debounced_search_field.dart';

import '../../domain/entities/operation_booking.dart';
import '../cubit/bookings_cubit.dart';
import '../cubit/bookings_state.dart';
import '../models/booking_filters.dart';
import '../models/booking_queue_tab.dart';
import '../models/booking_sort.dart';

/// الحجوزات' toolbar, built from the shared [DashboardFilterBar] so it is the
/// same control the other two المبيعات modules wear: queue tabs, then the
/// pinned search and ordering, then route / trip date / payment behind one
/// fold.
///
/// Priority filtering was removed because the concept has no backing column in
/// `operation_bookings`.
class BookingsToolbar extends StatelessWidget {
  const BookingsToolbar({super.key, required this.state});

  final BookingsLoaded state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BookingsCubit>();
    final filters = state.filters;

    return DashboardFilterBar(
      sectionId: DashboardSectionIds.bookingsFilters,
      tabs: DashboardQueueTabBar(
        tabs: [
          for (final tab in BookingQueueTab.values)
            DashboardQueueTab(
              label: tab.label,
              count: '${state.countForTab(tab)}',
              selected: state.activeTab == tab,
              urgent: tab == BookingQueueTab.needsReview,
              onTap: () => cubit.switchTab(tab),
            ),
        ],
      ),
      search: DebouncedSearchField(
        key: ValueKey('booking-search-${filters.search}'),
        initialValue: filters.search,
        hintText: 'ابحث برقم الحجز أو اسم الراكب أو الهاتف',
        onChanged: (value) =>
            cubit.updateFilters(filters.copyWith(search: value)),
      ),
      sort: DashboardSortControl<BookingSortField>(
        value: state.sortField,
        values: BookingSortField.values,
        labelOf: (field) => field.label,
        onChanged: cubit.sortBy,
        ascending: state.sortAscending,
        // `sortBy` flips the direction when it is handed the field already in
        // force, which is exactly what the arrow means.
        onToggleDirection: () => cubit.sortBy(state.sortField),
      ),
      filters: _Filters(state: state, cubit: cubit),
      filterSummary: _summary(state),
      activeFilterCount: filters.activeCount,
      onClearFilters: cubit.clearFilters,
    );
  }

  /// What the folded filter row is still doing, in the operator's own words.
  static List<String> _summary(BookingsLoaded state) {
    final filters = state.filters;
    if (!filters.isActive) return const ['بدون تصفية'];
    return [
      if (filters.search.trim().isNotEmpty) 'بحث: ${filters.search.trim()}',
      if (filters.route.trim().isNotEmpty) 'المسار: ${filters.route.trim()}',
      if (filters.date.trim().isNotEmpty) 'تاريخ الرحلة: ${filters.date}',
      if (filters.paymentMethod != null) filters.paymentMethod!.label,
      if (filters.paymentStatus != null) filters.paymentStatus!.label,
    ];
  }
}

/// Route, trip date and payment method/status — the filters an operator opens
/// a second click for.
class _Filters extends StatelessWidget {
  const _Filters({required this.state, required this.cubit});

  final BookingsLoaded state;
  final BookingsCubit cubit;

  @override
  Widget build(BuildContext context) {
    final filters = state.filters;
    void update(BookingFilters next) => cubit.updateFilters(next);

    // Routes come from the loaded bookings rather than a free-text box: typing
    // a substring that matches nothing silently returned an empty board with no
    // clue as to why.
    final routes = <String?>[
      null,
      ...({...state.availableRoutes, ?_selectedRoute}.toList()..sort()),
    ];

    return DashboardFilterFields(
      fields: [
        DashboardFilterDropdown<String?>(
          label: 'المسار',
          icon: Icons.route_rounded,
          value: _selectedRoute,
          values: routes,
          labelOf: (route) => route ?? 'كل المسارات',
          onChanged: (value) => update(filters.copyWith(route: value ?? '')),
        ),
        _TripDateFilter(
          value: filters.date,
          onChanged: (value) => update(filters.copyWith(date: value)),
        ),
        DashboardFilterDropdown<BookingPaymentMethod?>(
          label: 'طريقة الدفع',
          icon: Icons.account_balance_wallet_outlined,
          value: filters.paymentMethod,
          values: [null, ...BookingPaymentMethod.values],
          labelOf: (method) => method?.label ?? 'كل الطرق',
          onChanged: (value) => update(
            filters.copyWith(
              paymentMethod: value,
              clearPaymentMethod: value == null,
            ),
          ),
        ),
        DashboardFilterDropdown<PaymentStatus?>(
          label: 'حالة الدفع',
          icon: Icons.receipt_long_outlined,
          value: filters.paymentStatus,
          values: [null, ...PaymentStatus.values],
          labelOf: (status) => status?.label ?? 'كل الحالات',
          onChanged: (value) => update(
            filters.copyWith(
              paymentStatus: value,
              clearPaymentStatus: value == null,
            ),
          ),
        ),
      ],
    );
  }

  String? get _selectedRoute =>
      state.filters.route.isEmpty ? null : state.filters.route;
}

/// Trip-date filter backed by a real calendar.
///
/// The date was a free-text field whose value had to match the stored
/// `yyyy-MM-dd` exactly — an operator typing `27/7` filtered everything away.
class _TripDateFilter extends StatelessWidget {
  const _TripDateFilter({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  static String _iso(DateTime date) {
    String two(int v) => v.toString().padLeft(2, '0');

    return '${date.year}-${two(date.month)}-${two(date.day)}';
  }

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(value) ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      helpText: 'تصفية حسب تاريخ الرحلة',
    );
    if (picked != null) onChanged(_iso(picked));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasValue = value.trim().isNotEmpty;

    return InkWell(
      onTap: () => _pick(context),
      borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'تاريخ الرحلة',
          prefixIcon: const Icon(Icons.calendar_today_rounded),
          isDense: true,
          suffixIcon: hasValue
              ? IconButton(
                  tooltip: 'إلغاء تصفية التاريخ',
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () => onChanged(''),
                )
              : null,
        ),
        child: Text(
          hasValue ? value : 'كل التواريخ',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: hasValue ? scheme.onSurface : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
