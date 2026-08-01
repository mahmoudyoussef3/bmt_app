import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/ops_data_table.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/debounced_search_field.dart';

import '../../domain/entities/finance_entities.dart';
import '../cubit/finance_cubit.dart';
import '../cubit/finance_state.dart';
import 'finance_common.dart';
import 'finance_format.dart';

/// Every money movement in the window, searchable and filterable — and nothing
/// else. Rows are records, not queues: there is no action column here because
/// acting on a payment happens in Bookings.
class FinanceLedgerTab extends StatelessWidget {
  final FinanceLoaded state;

  const FinanceLedgerTab({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FinanceCubit>();
    final entries = state.filteredEntries;

    final pageCount = (entries.length / FinanceLoaded.ledgerPageSize)
        .ceil()
        .clamp(1, 9999);
    // Filters can shrink the result under the current page; clamp rather than
    // render an empty page the operator cannot explain.
    final page = state.ledgerPage.clamp(0, pageCount - 1);
    final pageEntries = entries
        .skip(page * FinanceLoaded.ledgerPageSize)
        .take(FinanceLoaded.ledgerPageSize)
        .toList();

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _LedgerFilters(state: state, cubit: cubit),
        const SizedBox(height: AppSpacing.medium),
        _LedgerTotals(state: state, shownCount: entries.length),
        const SizedBox(height: AppSpacing.medium),
        OpsDataTable(
          columns: const [
            OpsColumn('التاريخ', flex: 3, minWidth: 150),
            OpsColumn('النوع', flex: 2, minWidth: 110),
            OpsColumn('العميل', flex: 3, minWidth: 140),
            OpsColumn('المرجع', flex: 3, minWidth: 140),
            OpsColumn('طريقة الدفع', flex: 2, minWidth: 120),
            OpsColumn('الحالة', flex: 2, minWidth: 110),
            OpsColumn('المبلغ', flex: 2, numeric: true, minWidth: 130),
          ],
          rows: [for (final entry in pageEntries) _row(context, entry)],
          total: entries.length,
          currentPage: page,
          pageSize: FinanceLoaded.ledgerPageSize,
          onPageChanged: cubit.setLedgerPage,
          emptyLabel: state.hasAnyFilter
              ? 'لا توجد حركات مطابقة للبحث أو التصفية'
              : 'لا توجد حركات مالية في هذه الفترة',
        ),
      ],
    );
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
      Tooltip(
        message: entry.reference,
        child: Text(
          entry.reference,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ),
      Text(
        entry.method?.label ?? '—',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      FinanceStatusBadge(status: entry.status),
      Text(
        FinanceFormat.moneyPrecise(entry.amount),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          // A reversed row still shows what it was worth, struck through, so it
          // is never mistaken for revenue while scanning the column.
          decoration: entry.status == PaymentStatus.refunded
              ? TextDecoration.lineThrough
              : null,
          color: FinanceStatusBadge.colorOf(context, entry.status),
        ),
      ),
    ];
  }
}

class _LedgerFilters extends StatelessWidget {
  final FinanceLoaded state;
  final FinanceCubit cubit;

  const _LedgerFilters({required this.state, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final search = DebouncedSearchField(
      hintText: 'بحث باسم العميل، المسار، الباقة أو رقم العملية...',
      initialValue: state.searchQuery,
      onChanged: cubit.setSearchQuery,
    );

    final typeFilter = DropdownButtonFormField<FinanceEntryType?>(
      initialValue: state.typeFilter,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'نوع الحركة',
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('الكل')),
        for (final type in FinanceEntryType.values)
          DropdownMenuItem(value: type, child: Text(type.pluralLabel)),
      ],
      onChanged: cubit.setTypeFilter,
    );

    final methodFilter = DropdownButtonFormField<FinancePaymentMethod?>(
      initialValue: state.methodFilter,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'طريقة الدفع',
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('الكل')),
        for (final method in FinancePaymentMethod.values)
          DropdownMenuItem(value: method, child: Text(method.label)),
      ],
      onChanged: cubit.setMethodFilter,
    );

    final statusFilter = DropdownButtonFormField<PaymentStatus?>(
      initialValue: state.statusFilter,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'الحالة',
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('الكل')),
        for (final status in PaymentStatus.values)
          DropdownMenuItem(value: status, child: Text(status.label)),
      ],
      onChanged: cubit.setStatusFilter,
    );

    return AppCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 900;
          return Column(
            children: [
              if (narrow) ...[
                search,
                const SizedBox(height: AppSpacing.small),
                Row(
                  children: [
                    Expanded(child: typeFilter),
                    const SizedBox(width: AppSpacing.small),
                    Expanded(child: methodFilter),
                  ],
                ),
                const SizedBox(height: AppSpacing.small),
                statusFilter,
              ] else
                Row(
                  children: [
                    Expanded(flex: 3, child: search),
                    const SizedBox(width: AppSpacing.small),
                    Expanded(child: typeFilter),
                    const SizedBox(width: AppSpacing.small),
                    Expanded(child: methodFilter),
                    const SizedBox(width: AppSpacing.small),
                    Expanded(child: statusFilter),
                  ],
                ),
              if (state.hasAnyFilter) ...[
                const SizedBox(height: AppSpacing.small),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: cubit.clearFilters,
                    icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
                    label: const Text('مسح التصفية'),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Totals for what is actually on screen. A filtered ledger that still shows
/// the period total would invite the operator to read the wrong number.
class _LedgerTotals extends StatelessWidget {
  final FinanceLoaded state;
  final int shownCount;

  const _LedgerTotals({required this.state, required this.shownCount});

  @override
  Widget build(BuildContext context) {
    final palette = DashboardChartPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final analytics = state.analytics;

    return AppCard(
      child: Wrap(
        spacing: AppSpacing.large,
        runSpacing: AppSpacing.small,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _Total(
            label: state.hasAnyFilter ? 'المعروض حالياً' : 'حركات الفترة',
            value: '${FinanceFormat.count(shownCount)} حركة',
            color: palette.active,
            icon: Icons.list_alt_rounded,
          ),
          _Total(
            label: state.hasAnyFilter ? 'محصّل ضمن المعروض' : 'صافي المحصّل',
            value: FinanceFormat.money(
              state.hasAnyFilter ? state.filteredNet : analytics.netRevenue,
            ),
            color: palette.positive,
            icon: Icons.payments_outlined,
          ),
          _Total(
            label: 'قيد التحصيل',
            value: FinanceFormat.money(analytics.pending),
            color: palette.warning,
            icon: Icons.hourglass_bottom_rounded,
          ),
          _Total(
            label: 'مرتجعات',
            value: FinanceFormat.money(analytics.refunded),
            color: palette.negative,
            icon: Icons.undo_rounded,
          ),
          if (state.hasAnyFilter)
            Text(
              'التصفية تؤثر على العمود المعروض فقط، وليست على أرقام الفترة',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}

class _Total extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _Total({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.small),
          decoration: BoxDecoration(
            color: color.withAlpha(28),
            borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: AppSpacing.small),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ],
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
