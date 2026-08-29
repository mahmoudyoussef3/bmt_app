import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_filter_bar.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_queue_tabs.dart';
import 'package:bmt_app/core/widgets/debounced_search_field.dart';

import '../../domain/entities/wallet_transaction.dart';
import '../../domain/entities/wallet_vocabulary.dart';
import '../cubit/wallet_cubit.dart';
import '../cubit/wallet_state.dart';
import '../models/wallet_views.dart';
import 'wallet_format.dart';

/// محفظة العملاء' toolbar — the shared [DashboardFilterBar], one shape for all
/// three tabs.
///
/// The module used to answer "narrow this list" three different ways: the
/// directory had a bare search box and nothing else, الحركات had a tinted well
/// of eleven chips and a date row, and طلبات الاسترداد had no controls at all.
/// The three tabs now wear the console's one toolbar — surface strip, then a
/// **pinned** search and sort, then everything else behind one fold — so moving
/// between them costs no relearning, and the tab that had no filters has them.
///
/// The strip carries the module's own three surfaces rather than a per-tab set
/// of queues. That is what they are: one screen, three views of one office's
/// money, and the count on each pill says how much is behind it before you
/// press it.
class WalletToolbar extends StatelessWidget {
  const WalletToolbar({super.key, required this.state});

  final WalletLoadedState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<WalletCubit>();

    return DashboardFilterBar(
      // One fold per tab: the three filter sets are different controls, and a
      // shared key would have الاسترداد open just because الحركات was left open.
      sectionId: switch (state.tab) {
        WalletTab.directory => DashboardSectionIds.walletDirectoryFilters,
        WalletTab.activity => DashboardSectionIds.walletActivityFilters,
        WalletTab.refunds => DashboardSectionIds.walletRefundFilters,
      },
      tabs: DashboardQueueTabBar(
        tabs: [
          for (final tab in WalletTab.values)
            DashboardQueueTab(
              label: tab.label,
              count: WalletFormat.count(_countOf(tab)),
              selected: state.tab == tab,
              // Only the refund queue is *work*. A directory with 400 customers
              // in it is not a backlog, and badging it as one would make the
              // strip shout on every visit.
              urgent: tab == WalletTab.refunds,
              onTap: () => cubit.setTab(tab),
            ),
        ],
      ),
      search: _search(cubit),
      sort: _sort(cubit),
      filters: _Filters(state: state, cubit: cubit),
      filterSummary: _summary(),
      activeFilterCount: _activeCount(),
      onClearFilters: () => switch (state.tab) {
        WalletTab.directory => cubit.clearDirectoryFilters(),
        WalletTab.activity => cubit.applyFilters(const WalletLedgerFilters()),
        WalletTab.refunds => cubit.clearRefundFilters(),
      },
    );
  }

  int _countOf(WalletTab tab) => switch (tab) {
    WalletTab.directory => state.directory.total,
    WalletTab.activity => state.ledger.total,
    WalletTab.refunds => state.openRefundCount,
  };

  /// Keyed on the term so clearing the filters from anywhere else — a KPI tile,
  /// the reset button — resets the field rather than leaving stale text above a
  /// list it no longer describes.
  Widget _search(WalletCubit cubit) => switch (state.tab) {
    WalletTab.directory => DebouncedSearchField(
      key: ValueKey('wallet-directory-search-${state.directorySearch}'),
      initialValue: state.directorySearch,
      hintText: 'ابحث باسم العميل أو رقم الهاتف',
      onChanged: cubit.searchDirectory,
    ),
    WalletTab.activity => DebouncedSearchField(
      key: ValueKey('wallet-activity-search-${state.filters.search ?? ''}'),
      initialValue: state.filters.search ?? '',
      hintText: 'ابحث باسم العميل أو الهاتف أو رقم الحجز أو السبب',
      onChanged: (value) =>
          cubit.applyFilters(state.filters.copyWith(search: value)),
    ),
    WalletTab.refunds => DebouncedSearchField(
      key: ValueKey('wallet-refunds-search-${state.refundFilters.search}'),
      initialValue: state.refundFilters.search,
      hintText: 'ابحث باسم العميل أو رقم الحجز أو سبب الاسترداد',
      onChanged: (value) =>
          cubit.applyRefundFilters(state.refundFilters.copyWith(search: value)),
    ),
  };

  /// No direction toggle on any of the three: every key here has one sensible
  /// direction — the largest balance first, the newest movement first — and
  /// "the customer we owe least" is a control nobody would use standing in
  /// front of one everybody does.
  Widget _sort(WalletCubit cubit) => switch (state.tab) {
    WalletTab.directory => DashboardSortControl<WalletDirectorySort>(
      value: state.directoryFilters.sort,
      values: WalletDirectorySort.values,
      labelOf: (sort) => sort.label,
      onChanged: (sort) => cubit.applyDirectoryFilters(
        state.directoryFilters.copyWith(sort: sort),
      ),
    ),
    WalletTab.activity => DashboardSortControl<WalletActivitySort>(
      value: state.activitySort,
      values: WalletActivitySort.values,
      labelOf: (sort) => sort.label,
      onChanged: cubit.setActivitySort,
    ),
    WalletTab.refunds => DashboardSortControl<WalletRefundSort>(
      value: state.refundFilters.sort,
      values: WalletRefundSort.values,
      labelOf: (sort) => sort.label,
      onChanged: (sort) =>
          cubit.applyRefundFilters(state.refundFilters.copyWith(sort: sort)),
    ),
  };

  int _activeCount() => switch (state.tab) {
    WalletTab.directory =>
      state.directoryFilters.activeCount +
          (state.directorySearch.trim().isEmpty ? 0 : 1),
    WalletTab.activity => _ledgerActiveCount(state.filters),
    WalletTab.refunds => state.refundFilters.activeCount,
  };

  static int _ledgerActiveCount(WalletLedgerFilters filters) =>
      ((filters.search ?? '').trim().isEmpty ? 0 : 1) +
      (filters.kinds.isEmpty ? 0 : 1) +
      (filters.sources.isEmpty ? 0 : 1) +
      (filters.creditsOnly == null ? 0 : 1) +
      (filters.hasReversal == null ? 0 : 1) +
      (filters.from == null ? 0 : 1);

  /// What the folded row is still doing, in the operator's own words. Spelled
  /// out rather than counted: «٢ فلتر» makes the operator open the panel to
  /// find out which two, and a narrowed list read as a whole one is how money
  /// goes missing on screen.
  List<String> _summary() {
    final items = switch (state.tab) {
      WalletTab.directory => [
        if (state.directorySearch.trim().isNotEmpty)
          'بحث: ${state.directorySearch.trim()}',
        if (state.directoryFilters.scope != WalletDirectoryScope.all)
          state.directoryFilters.scope.label,
      ],
      WalletTab.activity => _ledgerSummary(state.filters),
      WalletTab.refunds => [
        if (state.refundFilters.search.trim().isNotEmpty)
          'بحث: ${state.refundFilters.search.trim()}',
        if (state.refundFilters.scope != WalletRefundScope.open)
          state.refundFilters.scope.label,
        if (state.refundFilters.source != WalletRefundSource.all)
          state.refundFilters.source.label,
        if (state.refundFilters.settlement != null)
          state.refundFilters.settlement!.label,
      ],
    };
    return items.isEmpty ? const ['بدون تصفية'] : items;
  }

  static List<String> _ledgerSummary(WalletLedgerFilters filters) => [
    if ((filters.search ?? '').trim().isNotEmpty)
      'بحث: ${filters.search!.trim()}',
    for (final kind in filters.kinds) kind.label,
    for (final source in filters.sources) source.label,
    if (filters.creditsOnly == true) 'إضافات فقط',
    if (filters.creditsOnly == false) 'خصومات فقط',
    if (filters.hasReversal == true) 'بها تصحيح',
    if (filters.from != null) 'منذ ${WalletFormat.date(filters.from!)}',
  ];
}

/// The foldable half of the toolbar. Every control is a
/// [DashboardFilterDropdown] on the shared field grid, so the three tabs' rows
/// line up with each other and with الحجوزات' next door — the previous chip
/// wall put eleven targets on one line and gave a filter with three states
/// (both / credits / debits) two independent chips that could contradict.
class _Filters extends StatelessWidget {
  const _Filters({required this.state, required this.cubit});

  final WalletLoadedState state;
  final WalletCubit cubit;

  @override
  Widget build(BuildContext context) => switch (state.tab) {
    WalletTab.directory => _directory(),
    WalletTab.activity => _activity(),
    WalletTab.refunds => _refunds(),
  };

  Widget _directory() {
    final filters = state.directoryFilters;
    return DashboardFilterFields(
      fields: [
        DashboardFilterDropdown<WalletDirectoryScope>(
          label: 'العملاء المعروضون',
          icon: Icons.filter_alt_outlined,
          value: filters.scope,
          values: WalletDirectoryScope.values,
          labelOf: (scope) => scope.label,
          onChanged: (scope) =>
              cubit.applyDirectoryFilters(filters.copyWith(scope: scope)),
        ),
      ],
    );
  }

  Widget _activity() {
    final filters = state.filters;
    return DashboardFilterFields(
      fields: [
        // One dropdown for a one-of-three axis. Two independent chips could be
        // pressed together and meant "credits and debits only", which is every
        // row — a filter that changes nothing while claiming to.
        DashboardFilterDropdown<bool?>(
          label: 'الاتجاه',
          icon: Icons.swap_vert_circle_outlined,
          value: filters.creditsOnly,
          values: const [null, true, false],
          labelOf: (value) => switch (value) {
            null => 'إضافات وخصومات',
            true => 'إضافات فقط',
            false => 'خصومات فقط',
          },
          onChanged: (value) => cubit.applyFilters(
            value == null
                ? filters.copyWith(clearDirection: true)
                : filters.copyWith(creditsOnly: value),
          ),
        ),
        DashboardFilterDropdown<WalletKind?>(
          label: 'نوع الحركة',
          icon: Icons.category_outlined,
          // `kinds` is a set server-side; the console offers one at a time,
          // which is what the operator actually asks for and what keeps this
          // field the same shape as its neighbours.
          value: filters.kinds.isEmpty ? null : filters.kinds.first,
          values: [null, ...WalletKind.active],
          labelOf: (kind) => kind?.label ?? 'كل الأنواع',
          onChanged: (kind) =>
              cubit.applyFilters(filters.copyWith(kinds: {?kind})),
        ),
        DashboardFilterDropdown<WalletSource?>(
          label: 'مصدر الحركة',
          icon: Icons.device_hub_outlined,
          value: filters.sources.isEmpty ? null : filters.sources.first,
          values: const [
            null,
            WalletSource.dashboard,
            WalletSource.client,
            WalletSource.system,
            WalletSource.migration,
          ],
          labelOf: (source) => source?.label ?? 'كل المصادر',
          onChanged: (source) =>
              cubit.applyFilters(filters.copyWith(sources: {?source})),
        ),
        DashboardFilterDropdown<bool?>(
          label: 'التصحيحات',
          icon: Icons.undo_rounded,
          value: filters.hasReversal,
          values: const [null, true],
          labelOf: (value) => value == null ? 'كل الحركات' : 'بها تصحيح',
          onChanged: (value) => cubit.applyFilters(
            value == null
                ? filters.copyWith(clearReversal: true)
                : filters.copyWith(hasReversal: true),
          ),
        ),
        _PeriodField(filters: filters, cubit: cubit),
      ],
    );
  }

  Widget _refunds() {
    final filters = state.refundFilters;
    return DashboardFilterFields(
      fields: [
        DashboardFilterDropdown<WalletRefundScope>(
          label: 'حالة الطلب',
          icon: Icons.rule_folder_outlined,
          value: filters.scope,
          values: WalletRefundScope.values,
          labelOf: (scope) => scope.label,
          onChanged: (scope) =>
              cubit.applyRefundFilters(filters.copyWith(scope: scope)),
        ),
        DashboardFilterDropdown<WalletRefundSource>(
          label: 'مصدر الطلب',
          icon: Icons.device_hub_outlined,
          value: filters.source,
          values: WalletRefundSource.values,
          labelOf: (source) => source.label,
          onChanged: (source) =>
              cubit.applyRefundFilters(filters.copyWith(source: source)),
        ),
        DashboardFilterDropdown<RefundSettlement?>(
          label: 'وجهة الصرف',
          icon: Icons.account_balance_outlined,
          value: filters.settlement,
          values: const [null, ...RefundSettlement.values],
          labelOf: (settlement) => settlement?.label ?? 'كل الوجهات',
          onChanged: (settlement) => cubit.applyRefundFilters(
            settlement == null
                ? filters.copyWith(clearSettlement: true)
                : filters.copyWith(settlement: settlement),
          ),
        ),
      ],
    );
  }
}

/// The ledger's date window, as one field rather than a row of preset chips.
///
/// The presets are what an operator reaches for — "today", "this week" — and
/// the open end is deliberate: the ledger's `to` is always now, so the control
/// asks one question ("how far back?") instead of two.
class _PeriodField extends StatelessWidget {
  const _PeriodField({required this.filters, required this.cubit});

  final WalletLedgerFilters filters;
  final WalletCubit cubit;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final presets = <int?>[null, 0, 7, 30, 90];

    DateTime? startOf(int? days) =>
        days == null ? null : today.subtract(Duration(days: days));

    // Matched by value, not by identity: the state holds a DateTime and the
    // options are recomputed on every build, so `==` on the date is the only
    // comparison that can find the current selection.
    final selected = presets.firstWhere(
      (days) => startOf(days) == filters.from,
      orElse: () => null,
    );

    return DashboardFilterDropdown<int?>(
      label: 'الفترة',
      icon: Icons.calendar_month_outlined,
      value: selected,
      values: presets,
      labelOf: (days) => switch (days) {
        null => 'كل الفترات',
        0 => 'اليوم',
        7 => 'آخر ٧ أيام',
        30 => 'آخر ٣٠ يومًا',
        _ => 'آخر ٩٠ يومًا',
      },
      onChanged: (days) => cubit.applyFilters(
        days == null
            ? filters.copyWith(clearDates: true)
            : filters.copyWith(from: startOf(days)),
      ),
    );
  }
}
