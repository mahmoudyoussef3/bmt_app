import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_collapsible_section.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/debounced_search_field.dart';

import '../../domain/entities/operation_booking.dart';
import '../cubit/bookings_cubit.dart';
import '../cubit/bookings_state.dart';
import '../models/booking_filters.dart';
import '../models/booking_queue_tab.dart';

/// Queue tabs + the filter row beneath them.
///
/// Priority filtering was removed because the concept has no backing column in
/// `operation_bookings`.
class BookingsToolbar extends StatelessWidget {
  const BookingsToolbar({super.key, required this.state});

  final BookingsLoaded state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cubit = context.read<BookingsCubit>();

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.medium,
              AppSpacing.medium,
              AppSpacing.medium,
              0,
            ),
            child: BookingQueueTabBar(
              state: state,
              onSelected: cubit.switchTab,
            ),
          ),
          const SizedBox(height: AppSpacing.medium),
          Divider(height: 1, color: scheme.outline.withAlpha(60)),
          // Only the filter row folds — the queue tabs above are navigation and
          // stay put, because collapsing them would hide which queue is open.
          DashboardCollapsibleSection.bare(
            sectionId: DashboardSectionIds.bookingsFilters,
            icon: Icons.filter_alt_outlined,
            title: 'التصفية',
            collapsedSummary: DashboardSectionSummary(
              items: _filterSummary(state.filters),
            ),
            child: _FiltersBar(state: state, cubit: cubit),
          ),
        ],
      ),
    );
  }

  /// Spells the active filters out rather than only counting them: "٢ فلتر" makes
  /// an operator reopen the panel to find out *which* two.
  static List<String> _filterSummary(BookingFilters filters) {
    if (!filters.isActive) return const ['بدون تصفية'];
    return [
      if (filters.search.trim().isNotEmpty) 'بحث: ${filters.search.trim()}',
      if (filters.route.trim().isNotEmpty) 'مسار: ${filters.route.trim()}',
      if (filters.date.trim().isNotEmpty) 'تاريخ: ${filters.date.trim()}',
      if (filters.paymentMethod != null) filters.paymentMethod!.label,
      if (filters.paymentStatus != null) filters.paymentStatus!.label,
    ];
  }
}

/// Horizontally scrollable pills, each carrying its own count.
///
/// The counts used to be glued into the label with two spaces
/// (`'محجوز  12'`), which read as a typo at a glance and gave the eye nothing
/// to lock onto; they are now badges, so the queue depth is scannable.
class BookingQueueTabBar extends StatelessWidget {
  const BookingQueueTabBar({
    super.key,
    required this.state,
    required this.onSelected,
  });

  final BookingsLoaded state;
  final ValueChanged<BookingQueueTab> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final tab in BookingQueueTab.values)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.small),
              child: _QueueTab(
                label: tab.label,
                count: state.countForTab(tab),
                selected: state.activeTab == tab,
                // The review queue is the only tab that represents outstanding
                // work, so it stays visually distinct even when unselected.
                urgent: tab == BookingQueueTab.needsReview,
                onTap: () => onSelected(tab),
              ),
            ),
        ],
      ),
    );
  }
}

class _QueueTab extends StatelessWidget {
  const _QueueTab({
    required this.label,
    required this.count,
    required this.selected,
    required this.urgent,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final bool urgent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final accent = urgent && count > 0 ? scheme.tertiary : scheme.primary;
    final background = selected ? accent : scheme.surfaceContainerHighest;
    final foreground = selected ? scheme.onPrimary : scheme.onSurface;

    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: AppTokens.motionFast,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.medium,
              vertical: AppSpacing.small,
            ),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected ? accent : scheme.outline.withAlpha(90),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: text.labelLarge?.copyWith(
                    color: foreground,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                  ),
                ),
                const SizedBox(width: AppSpacing.small),
                Container(
                  constraints: const BoxConstraints(minWidth: 22),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? scheme.onPrimary.withAlpha(55)
                        : accent.withAlpha(28),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$count',
                    textAlign: TextAlign.center,
                    style: text.labelSmall?.copyWith(
                      color: selected ? scheme.onPrimary : accent,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FiltersBar extends StatelessWidget {
  const _FiltersBar({required this.state, required this.cubit});

  final BookingsLoaded state;
  final BookingsCubit cubit;

  @override
  Widget build(BuildContext context) {
    final filters = state.filters;
    void update(BookingFilters next) => cubit.updateFilters(next);

    return LayoutBuilder(
      builder: (context, constraints) {
        final full = constraints.maxWidth;
        final compact = full < 720;
        // Two fields per row on mid widths, one per row on phones: a Wrap of
        // fixed 220px fields left ragged half-empty rows at tablet size.
        final double fieldWidth = compact
            ? full
            : full < 1080
            ? (full - AppSpacing.small) / 2
            : 210;

        return Wrap(
          spacing: AppSpacing.small,
          runSpacing: AppSpacing.small,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: compact ? full : (full < 1080 ? fieldWidth : 280),
              child: DebouncedSearchField(
                // Keyed on the filter value so "clear filters" actually empties
                // the box: the field owns its controller, and without a rebuilt
                // element it would keep showing the stale query.
                key: ValueKey('booking-search-${filters.search}'),
                initialValue: filters.search,
                hintText: 'اسم، هاتف، رقم حجز، مقعد',
                onChanged: (value) => update(filters.copyWith(search: value)),
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: _RouteFilter(
                routes: state.availableRoutes,
                value: filters.route.isEmpty ? null : filters.route,
                onChanged: (value) =>
                    update(filters.copyWith(route: value ?? '')),
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: _TripDateFilter(
                value: filters.date,
                onChanged: (value) => update(filters.copyWith(date: value)),
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: DropdownButtonFormField<BookingPaymentMethod?>(
                initialValue: filters.paymentMethod,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'طريقة الدفع',
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem<BookingPaymentMethod?>(
                    value: null,
                    child: Text('كل الطرق'),
                  ),
                  ...BookingPaymentMethod.values.map(
                    (method) => DropdownMenuItem(
                      value: method,
                      child: Text(method.label),
                    ),
                  ),
                ],
                onChanged: (value) => update(
                  filters.copyWith(
                    paymentMethod: value,
                    clearPaymentMethod: value == null,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: DropdownButtonFormField<PaymentStatus?>(
                initialValue: filters.paymentStatus,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'حالة الدفع',
                  prefixIcon: Icon(Icons.receipt_long_outlined),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem<PaymentStatus?>(
                    value: null,
                    child: Text('كل الحالات'),
                  ),
                  ...PaymentStatus.values.map(
                    (status) => DropdownMenuItem(
                      value: status,
                      child: Text(status.label),
                    ),
                  ),
                ],
                onChanged: (value) => update(
                  filters.copyWith(
                    paymentStatus: value,
                    clearPaymentStatus: value == null,
                  ),
                ),
              ),
            ),
            if (filters.isActive)
              SizedBox(
                width: compact ? full : null,
                child: OutlinedButton.icon(
                  onPressed: cubit.clearFilters,
                  icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
                  label: Text('مسح الفلاتر (${filters.activeCount})'),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Routes come from the loaded bookings rather than a free-text box: typing a
/// substring that matches nothing silently returned an empty board with no clue
/// as to why.
class _RouteFilter extends StatelessWidget {
  const _RouteFilter({
    required this.routes,
    required this.value,
    required this.onChanged,
  });

  final List<String> routes;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    // A route can disappear from the data (last booking on it approved away)
    // while still selected; keeping it in the item list prevents a dropdown
    // assertion on a value with no matching item.
    final items = {...routes, ?value}.toList()..sort();

    return DropdownButtonFormField<String?>(
      initialValue: value,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'المسار',
        prefixIcon: Icon(Icons.route_rounded),
        isDense: true,
      ),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('كل المسارات'),
        ),
        ...items.map(
          (route) => DropdownMenuItem(
            value: route,
            child: Text(route, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
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
    // Written by hand rather than through MaterialLocalizations: under the
    // dashboard's `ar` locale those formatters emit Arabic-Indic digits, which
    // would never match the ASCII `trip_date` values being filtered.
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
