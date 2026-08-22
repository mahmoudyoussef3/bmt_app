import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/routes/dashboard_routes.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_empty_state.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_kpi_card.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/ops_data_table.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/debounced_search_field.dart';
import 'package:bmt_app/core/widgets/route_direction_text.dart';

import '../../domain/entities/finance_entities.dart';
import '../cubit/finance_cubit.dart';
import '../cubit/finance_state.dart';
import 'finance_common.dart';
import 'finance_format.dart';
import 'finance_transaction_detail.dart';

/// Every money movement in the window, searchable, filterable and openable —
/// and nothing else. Rows are records, not queues: there is no action column
/// here because acting on a payment happens in Bookings. A row does open into
/// its full context, which is reading, not deciding.
class FinanceLedgerTab extends StatelessWidget {
  final FinanceLoaded state;
  final ValueChanged<String>? onOpenModule;

  const FinanceLedgerTab({super.key, required this.state, this.onOpenModule});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FinanceCubit>();
    final entries = state.filteredEntries;

    final pageCount = (entries.length / FinanceLoaded.ledgerPageSize)
        .ceil()
        .clamp(1, 9999);

    final page = state.ledgerPage.clamp(0, pageCount - 1);
    final pageEntries = entries
        .skip(page * FinanceLoaded.ledgerPageSize)
        .take(FinanceLoaded.ledgerPageSize)
        .toList();

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _LedgerKpiRow(
          state: state,
          shownCount: entries.length,
          onOpenModule: onOpenModule,
        ),
        const SizedBox(height: AppSpacing.medium),
        OpsDataTable(
          toolbar: _LedgerToolbar(state: state, cubit: cubit),
          // `flex` equals `minWidth` on every column — see the Routes/Trips
          // table trap: [OpsDataTable] splits its rendered width by flex
          // *fraction*, not by minWidth, so at the exact-minWidth boundary a
          // column whose flex-share undercuts its own minWidth still gets
          // squeezed below it and overflows even though the table as a whole
          // is wide enough. Matching the two exactly avoids that.
          columns: const [
            OpsColumn('التاريخ', flex: 150, minWidth: 150),
            OpsColumn('النوع', flex: 110, minWidth: 110),
            OpsColumn('العميل', flex: 140, minWidth: 140),
            OpsColumn('المرجع', flex: 180, minWidth: 180),
            OpsColumn('طريقة الدفع', flex: 120, minWidth: 120),
            OpsColumn('الحالة', flex: 130, minWidth: 130),
            OpsColumn('المبلغ', flex: 130, numeric: true, minWidth: 130),
          ],
          rows: [for (final entry in pageEntries) _row(context, entry)],
          onRowTap: [
            for (final entry in pageEntries)
              () => _openDetail(context, entry),
          ],

          // A tint, never a tint alone: the same rows carry an explicit
          // "يحتاج مراجعة" / "مقعد ملغي" pill in the status column.
          rowTints: [
            for (final entry in pageEntries) _tintFor(context, entry),
          ],
          total: entries.length,
          currentPage: page,
          pageSize: FinanceLoaded.ledgerPageSize,
          onPageChanged: cubit.setLedgerPage,
          emptyState: _emptyState(context, cubit),
        ),
      ],
    );
  }

  Widget _emptyState(BuildContext context, FinanceCubit cubit) {
    if (state.hasAnyFilter) {
      return DashboardEmptyState(
        icon: Icons.filter_alt_off_rounded,
        title: 'لا توجد حركات مطابقة',
        message: 'البحث والتصفية الحالية لا يطابقان أي حركة داخل هذه الفترة.',
        action: TextButton.icon(
          onPressed: cubit.clearFilters,
          icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
          label: const Text('مسح التصفية'),
        ),
      );
    }

    if (state.hasNoHistory) {
      return const DashboardEmptyState(
        icon: DashboardIcons.payments,
        title: 'لا توجد حركات مالية بعد',
        message:
            'لم يُسجَّل أي حجز أو اشتراك على هذا المكتب حتى الآن. '
            'أول عملية بيع ستظهر هنا فوراً.',
      );
    }

    return DashboardEmptyState(
      icon: Icons.event_busy_rounded,
      title: 'لا توجد حركات في ${state.analytics.periodLabel}',
      message:
          'السجل يحتوي حركات في فترات أخرى — وسّع الفترة من الشريط أعلى الصفحة.',
      action: TextButton.icon(
        onPressed: () => cubit.setPeriod(FinancePeriod.all),
        icon: const Icon(Icons.all_inclusive_rounded, size: 18),
        label: const Text('اعرض كل الفترات'),
      ),
    );
  }

  void _openDetail(BuildContext context, FinanceLedgerEntry entry) {
    FinanceTransactionDetail.show(
      context,
      entry: entry,
      refund: _refundFor(entry),
      onOpenModule: onOpenModule,
    );
  }

  /// The refund request that reverses [entry], if there is one.
  ///
  /// `refund_requests.booking_id` is the join, so only a booking can carry one;
  /// a linear scan is right here because it runs once, on a click, over a list
  /// that is orders of magnitude shorter than the ledger.
  RefundRequest? _refundFor(FinanceLedgerEntry entry) {
    if (entry.type != FinanceEntryType.booking) return null;
    for (final request in state.refundRequests) {
      if (request.transactionId == entry.id) return request;
    }
    return null;
  }

  Color? _tintFor(BuildContext context, FinanceLedgerEntry entry) {
    final palette = DashboardChartPalette.of(context);
    if (entry.isUnreleasedLiability) {
      return Theme.of(context).colorScheme.error.withAlpha(16);
    }
    if (entry.awaitingReview) return palette.warning.withAlpha(16);
    return null;
  }

  List<Widget> _row(BuildContext context, FinanceLedgerEntry entry) {
    final scheme = Theme.of(context).colorScheme;
    return [
      Text(
        FinanceFormat.dateTime(entry.date),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      _TypeChip(type: entry.type),
      Text(
        entry.party,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      _ReferenceCell(entry: entry),
      Text(
        entry.method?.label ?? '—',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          FinanceStatusBadge(status: entry.status),
          if (entry.awaitingReview || entry.isUnreleasedLiability)
            Text(
              entry.isUnreleasedLiability ? 'مقعد ملغي' : 'يحتاج مراجعة',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: entry.isUnreleasedLiability
                    ? scheme.error
                    : scheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
      Text(
        FinanceFormat.moneyPrecise(entry.amount),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: FontWeight.w900,

          decoration: entry.status == PaymentStatus.refunded
              ? TextDecoration.lineThrough
              : null,
          color: FinanceStatusBadge.colorOf(context, entry.status),
        ),
      ),
    ];
  }
}

/// The journey or the package, composed rather than printed.
///
/// `operation_bookings.route` stores the pair already joined with an arrow, and
/// printing it raw announces the trip backwards whenever bidi resolves the line
/// the other way — which, for the Latin place names the geocoder returns for
/// most Egyptian stops, is most of the time.
class _ReferenceCell extends StatelessWidget {
  const _ReferenceCell({required this.entry});

  final FinanceLedgerEntry entry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    final origin = entry.context.origin;
    final destination = entry.context.destination;

    return Tooltip(
      message: entry.context.reference == null
          ? entry.reference
          : '${entry.context.reference} — ${entry.reference}',
      child: origin != null && destination != null
          ? RouteDirectionText(
              origin: origin,
              destination: destination,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            )
          : Text(
              entry.reference,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
    );
  }
}

/// The four numbers an operator needs before touching a filter: what the
/// window collected, what still needs a receipt decision, what is still
/// outstanding, and what went back. Same shape as every other EWT table
/// module (Routes, Trips) — a plain emphasized card, no fabricated figure.
///
/// "بانتظار المراجعة" is the one tile with somewhere to go: Finance never
/// decides a receipt, so tapping it hands the operator to الحجوزات, exactly
/// like [FinanceAttentionPanel] does for the same queue.
class _LedgerKpiRow extends StatelessWidget {
  final FinanceLoaded state;
  final int shownCount;
  final ValueChanged<String>? onOpenModule;

  const _LedgerKpiRow({
    required this.state,
    required this.shownCount,
    this.onOpenModule,
  });

  @override
  Widget build(BuildContext context) {
    final palette = DashboardChartPalette.of(context);
    final analytics = state.analytics;

    // Scoped to the selected window, unlike [FinanceAttention] (whole book) —
    // every other figure on this tab is window-scoped and a mixed pair would
    // silently disagree with the period bar above it.
    final reviewEntries = analytics.entries.where((e) => e.awaitingReview);
    final reviewCount = reviewEntries.length;
    final reviewAmount = reviewEntries.fold(0.0, (sum, e) => sum + e.amount);

    return DashboardKpiGrid(
      itemExtent: 116,
      children: [
        DashboardKpiCard(
          emphasized: true,
          icon: Icons.payments_outlined,
          label: state.hasAnyFilter ? 'محصّل ضمن المعروض' : 'صافي المحصّل',
          value: FinanceFormat.money(
            state.hasAnyFilter ? state.filteredNet : analytics.netRevenue,
          ),
          detail: state.hasAnyFilter
              ? '${FinanceFormat.count(shownCount)} من '
                    '${FinanceFormat.count(analytics.entries.length)} حركة'
              : analytics.periodLabel,
          color: palette.positive,
        ),
        DashboardKpiCard(
          emphasized: true,
          icon: Icons.pending_actions_outlined,
          label: 'بانتظار المراجعة',
          value: FinanceFormat.count(reviewCount),
          detail: '${FinanceFormat.money(reviewAmount)} · إيصالات',
          color: palette.warning,
          onTap: reviewCount == 0
              ? null
              : () => onOpenModule?.call(DashboardRoutes.paymentVerification),
          tapHint: reviewCount == 0 ? null : 'راجع الإيصالات في الحجوزات',
        ),
        DashboardKpiCard(
          emphasized: true,
          icon: Icons.hourglass_bottom_rounded,
          label: 'مستحق غير محصّل',
          value: FinanceFormat.money(analytics.receivable),
          detail: '${FinanceFormat.count(analytics.pendingCount)} عملية قائمة',
          color: palette.warning,
        ),
        DashboardKpiCard(
          emphasized: true,
          icon: Icons.undo_rounded,
          label: 'مرتجعات الفترة',
          value: FinanceFormat.money(analytics.refunded),
          detail: '${FinanceFormat.percent(analytics.refundRate)} من المتحصل',
          color: palette.negative,
        ),
      ],
    );
  }
}

/// Search, quick status chips and the advanced-filter trigger — rendered
/// inside [OpsDataTable]'s toolbar slot, above its sticky column header. Same
/// shape every other EWT table module (Trips, Routes) uses.
class _LedgerToolbar extends StatelessWidget {
  final FinanceLoaded state;
  final FinanceCubit cubit;

  const _LedgerToolbar({required this.state, required this.cubit});

  int _countOf(PaymentStatus? status) => status == null
      ? state.analytics.entries.length
      : state.analytics.entries.where((e) => e.status == status).length;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final search = DebouncedSearchField(
          hintText: 'بحث بالاسم، رقم الحجز، الهاتف، المسار أو الباقة...',
          initialValue: state.searchQuery,
          onChanged: cubit.setSearchQuery,
        );
        final advancedFilter = _AdvancedFilterButton(state: state, cubit: cubit);
        final chips = Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _StatusChip(
              label: 'الكل ${FinanceFormat.count(_countOf(null))}',
              selected: state.statusFilter == null,
              onSelected: () => cubit.setStatusFilter(null),
            ),
            for (final status in PaymentStatus.values)
              _StatusChip(
                label: '${status.label} ${FinanceFormat.count(_countOf(status))}',
                selected: state.statusFilter == status,
                onSelected: () => cubit.setStatusFilter(status),
              ),
          ],
        );

        if (constraints.maxWidth < 900) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: search),
                  const SizedBox(width: 8),
                  advancedFilter,
                ],
              ),
              const SizedBox(height: 10),
              chips,
            ],
          );
        }
        return Row(
          children: [
            SizedBox(width: 280, child: search),
            const SizedBox(width: 12),
            Expanded(child: chips),
            const SizedBox(width: 12),
            advancedFilter,
          ],
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      labelStyle: const TextStyle(fontWeight: FontWeight.w700),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onSelected(),
    );
  }
}

/// The dimensions the quick chips leave out — نوع الحركة, طريقة الدفع and
/// الترتيب — behind one "تصفية متقدمة" sheet rather than three dropdowns
/// crowding the toolbar. Unlike [RoutesListView]'s single-choice sheet this
/// one holds three independent groups, so a selection never auto-closes it.
class _AdvancedFilterButton extends StatelessWidget {
  const _AdvancedFilterButton({required this.state, required this.cubit});

  final FinanceLoaded state;
  final FinanceCubit cubit;

  bool get _isActive => state.typeFilter != null || state.methodFilter != null;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        OutlinedButton.icon(
          onPressed: () => _openSheet(context),
          icon: const Icon(Icons.tune_rounded, size: 18),
          label: const Text('تصفية متقدمة'),
        ),
        if (_isActive)
          PositionedDirectional(
            end: 6,
            top: 6,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }

  void _openSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SheetHeading(text: 'نوع الحركة'),
                RadioGroup<FinanceEntryType?>(
                  groupValue: state.typeFilter,
                  onChanged: cubit.setTypeFilter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const RadioListTile<FinanceEntryType?>(
                        contentPadding: EdgeInsets.zero,
                        title: Text('الكل'),
                        value: null,
                      ),
                      for (final type in FinanceEntryType.values)
                        RadioListTile<FinanceEntryType?>(
                          contentPadding: EdgeInsets.zero,
                          title: Text(type.pluralLabel),
                          value: type,
                        ),
                    ],
                  ),
                ),
                const Divider(),
                _SheetHeading(text: 'طريقة الدفع'),
                RadioGroup<FinancePaymentMethod?>(
                  groupValue: state.methodFilter,
                  onChanged: cubit.setMethodFilter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const RadioListTile<FinancePaymentMethod?>(
                        contentPadding: EdgeInsets.zero,
                        title: Text('الكل'),
                        value: null,
                      ),
                      for (final method in FinancePaymentMethod.values)
                        RadioListTile<FinancePaymentMethod?>(
                          contentPadding: EdgeInsets.zero,
                          title: Text(method.label),
                          value: method,
                        ),
                    ],
                  ),
                ),
                const Divider(),
                _SheetHeading(text: 'الترتيب'),
                RadioGroup<FinanceLedgerSort>(
                  groupValue: state.ledgerSort,
                  onChanged: (sort) {
                    if (sort != null) cubit.setLedgerSort(sort);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final sort in FinanceLedgerSort.values)
                        RadioListTile<FinanceLedgerSort>(
                          contentPadding: EdgeInsets.zero,
                          title: Text(sort.label),
                          value: sort,
                        ),
                    ],
                  ),
                ),
                if (state.hasAnyFilter) ...[
                  const SizedBox(height: AppSpacing.small),
                  TextButton.icon(
                    onPressed: () {
                      cubit.clearFilters();
                      Navigator.pop(sheetContext);
                    },
                    icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
                    label: const Text('مسح كل التصفية'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetHeading extends StatelessWidget {
  const _SheetHeading({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xSmall),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final FinanceEntryType type;

  const _TypeChip({required this.type});

  @override
  Widget build(BuildContext context) {
    final palette = DashboardChartPalette.of(context);
    final color = switch (type) {
      FinanceEntryType.booking => palette.active,
      FinanceEntryType.subscription => palette.accent,
    };
    final icon = switch (type) {
      FinanceEntryType.booking => Icons.event_seat_outlined,
      FinanceEntryType.subscription => Icons.workspace_premium_outlined,
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            type.pluralLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
