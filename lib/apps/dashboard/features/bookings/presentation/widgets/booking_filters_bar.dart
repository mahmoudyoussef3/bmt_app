import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/debounced_search_field.dart';

import '../../domain/entities/operation_booking.dart';
import '../cubit/bookings_cubit.dart';
import '../cubit/bookings_state.dart';
import '../models/booking_filters.dart';
import '../models/booking_queue_tab.dart';

/// Queue tabs, the always-visible search, and the advanced filters an
/// operator opens on demand.
///
/// Search sits next to the tabs rather than behind the advanced toggle: it is
/// the one field an operator reaches for on almost every visit, while route,
/// trip date and payment method/status are the ones worth a second click.
/// Priority filtering was removed because the concept has no backing column in
/// `operation_bookings`.
class BookingsToolbar extends StatefulWidget {
  const BookingsToolbar({super.key, required this.state});

  final BookingsLoaded state;

  @override
  State<BookingsToolbar> createState() => _BookingsToolbarState();
}

class _BookingsToolbarState extends State<BookingsToolbar> {
  late bool _advancedExpanded = DashboardSectionStateStore.instance.isExpanded(
    DashboardSectionIds.bookingsFilters,
    fallback: false,
  );

  void _toggleAdvanced() {
    final next = !_advancedExpanded;
    setState(() => _advancedExpanded = next);
    DashboardSectionStateStore.instance.setExpanded(
      DashboardSectionIds.bookingsFilters,
      next,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cubit = context.read<BookingsCubit>();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MainRow(
            state: widget.state,
            cubit: cubit,
            advancedExpanded: _advancedExpanded,
            onToggleAdvanced: _toggleAdvanced,
          ),
          if (_advancedExpanded) ...[
            const SizedBox(height: AppSpacing.medium),
            Divider(height: 1, color: scheme.outline.withAlpha(60)),
            const SizedBox(height: AppSpacing.medium),
            _AdvancedFiltersBar(state: widget.state, cubit: cubit),
          ],
        ],
      ),
    );
  }
}

/// The row that is always on screen: the advanced-filters toggle, the queue
/// tabs, and search — in that visual order (right to left in this RTL app),
/// matching the "تصفية متقدمة … search" bar the board is opened to.
class _MainRow extends StatelessWidget {
  const _MainRow({
    required this.state,
    required this.cubit,
    required this.advancedExpanded,
    required this.onToggleAdvanced,
  });

  final BookingsLoaded state;
  final BookingsCubit cubit;
  final bool advancedExpanded;
  final VoidCallback onToggleAdvanced;

  /// Filters the advanced panel actually owns — search lives in this row, so
  /// it is not counted toward "how many are hiding behind that button".
  int get _advancedActiveCount {
    final filters = state.filters;
    return [
      filters.route.trim().isNotEmpty,
      filters.date.trim().isNotEmpty,
      filters.paymentMethod != null,
      filters.paymentStatus != null,
    ].where((active) => active).length;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final filters = state.filters;
    final activeCount = _advancedActiveCount;

    final advancedButton = OutlinedButton.icon(
      onPressed: onToggleAdvanced,
      style: OutlinedButton.styleFrom(
        foregroundColor: advancedExpanded || activeCount > 0
            ? scheme.primary
            : null,
        side: BorderSide(
          color: advancedExpanded || activeCount > 0
              ? scheme.primary
              : scheme.outline.withAlpha(90),
        ),
      ),
      icon: Icon(
        advancedExpanded ? Icons.expand_less_rounded : Icons.tune_rounded,
        size: 18,
      ),
      label: Text(
        activeCount > 0 ? 'تصفية متقدمة ($activeCount)' : 'تصفية متقدمة',
      ),
    );

    final search = DebouncedSearchField(
      key: ValueKey('booking-search-${filters.search}'),
      initialValue: filters.search,
      hintText: 'ابحث برقم الحجز أو اسم الراكب أو الهاتف',
      onChanged: (value) =>
          cubit.updateFilters(filters.copyWith(search: value)),
    );

    final tabs = BookingQueueTabBar(state: state, onSelected: cubit.switchTab);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 760) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              tabs,
              const SizedBox(height: AppSpacing.small),
              search,
              const SizedBox(height: AppSpacing.small),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: advancedButton,
              ),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(width: 280, child: search),
            const SizedBox(width: AppSpacing.medium),
            Expanded(child: tabs),
            const SizedBox(width: AppSpacing.medium),
            advancedButton,
          ],
        );
      },
    );
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

    final accent = scheme.primary;
    final background = selected ? accent : scheme.surfaceContainerHighest;
    final foreground = selected ? scheme.onPrimary : scheme.onSurface;

    final isUrgentAlert = urgent && count > 0 && !selected;

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
                    color: isUrgentAlert
                        ? scheme.error
                        : selected
                        ? scheme.onPrimary.withAlpha(55)
                        : accent.withAlpha(28),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$count',
                    textAlign: TextAlign.center,
                    style: text.labelSmall?.copyWith(
                      color: isUrgentAlert
                          ? scheme.onError
                          : selected
                          ? scheme.onPrimary
                          : accent,
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

/// Route, trip date and payment method/status — the filters an operator opens
/// a second click for, shown under the toggle in [_MainRow].
class _AdvancedFiltersBar extends StatelessWidget {
  const _AdvancedFiltersBar({required this.state, required this.cubit});

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
