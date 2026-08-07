import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/ops_data_table.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../../domain/entities/finance_analytics.dart';
import '../../domain/entities/finance_entities.dart';
import '../cubit/finance_cubit.dart';
import '../cubit/finance_state.dart';
import 'finance_common.dart';
import 'finance_format.dart';

/// The formal read: an income statement for the period, the breakdowns that
/// support it, and the same content downloadable as PDF / Excel / CSV.
class FinanceReportsTab extends StatelessWidget {
  final FinanceLoaded state;

  const FinanceReportsTab({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final analytics = state.analytics;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _ExportToolbar(state: state),
        const SizedBox(height: AppSpacing.medium),
        _IncomeStatement(analytics: analytics),
        const SizedBox(height: AppSpacing.medium),
        DashboardPanel(
          sectionId: DashboardSectionIds.financeCollectionByMethod,
          icon: Icons.account_balance_rounded,
          title: 'التحصيل حسب طريقة الدفع',
          subtitle: 'أين يدخل المال فعلياً خلال ${analytics.period.label}',
          child: _MethodTable(analytics: analytics),
        ),
        const SizedBox(height: AppSpacing.medium),
        DashboardPanel(
          sectionId: DashboardSectionIds.financeRefundRequests,
          icon: Icons.pending_actions_outlined,
          title: 'طلبات الاسترداد',
          subtitle:
              'التزامات محتملة على الفترة — القرار عليها يتم في قسم الحجوزات',
          child: _RefundRequestsSummary(state: state),
        ),
        const SizedBox(height: AppSpacing.medium),
        _DailyTable(analytics: analytics),
      ],
    );
  }
}

class _ExportToolbar extends StatelessWidget {
  final FinanceLoaded state;

  const _ExportToolbar({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FinanceCubit>();
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final title = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.ios_share_rounded, color: scheme.primary),
                  const SizedBox(width: AppSpacing.small),
                  Flexible(
                    child: Text(
                      'تصدير التقرير المالي — ${state.period.label}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'الملف يحتوي قائمة الدخل، التوزيع حسب طريقة الدفع، الحركة اليومية وسجل الحركات — بنفس أرقام الشاشة.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          );

          final actions = state.exporting
              ? const [
                  SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ]
              : [
                  FilledButton.icon(
                    onPressed: () => cubit.exportStatement('pdf'),
                    icon: const Icon(Icons.picture_as_pdf_rounded),
                    label: const Text('PDF'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => cubit.exportStatement('excel'),
                    icon: const Icon(Icons.grid_on_rounded),
                    label: const Text('Excel'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => cubit.exportStatement('csv'),
                    icon: const Icon(Icons.description_outlined),
                    label: const Text('CSV'),
                  ),
                ];

          final actionBar = Wrap(
            spacing: AppSpacing.small,
            runSpacing: AppSpacing.small,
            children: actions,
          );

          if (constraints.maxWidth < 720) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title,
                const SizedBox(height: AppSpacing.medium),
                actionBar,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: title),
              const SizedBox(width: AppSpacing.medium),
              actionBar,
            ],
          );
        },
      ),
    );
  }
}

/// Reads top to bottom like a statement: what came in, what went back out, and
/// the line the owner actually keeps — with the excluded figures shown as memo
/// lines rather than quietly dropped.
class _IncomeStatement extends StatelessWidget {
  final FinanceAnalytics analytics;

  const _IncomeStatement({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final palette = DashboardChartPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final statement = analytics.toStatement(generatedAt: DateTime.now());
    final memoLines = statement.summary.where((line) => line.isMemo).toList();
    final mainLines = statement.summary.where((line) => !line.isMemo).toList();

    return DashboardPanel(
      sectionId: DashboardSectionIds.financeIncomeStatement,
      icon: Icons.request_quote_outlined,
      title: 'قائمة الدخل — ${analytics.period.label}',
      subtitle:
          'صافي الإيراد = إجمالي المتحصلات − المرتجعات المنفذة. المبالغ المعلقة والملغاة خارج الحساب.',
      child: Column(
        children: [
          for (final line in mainLines) ...[
            if (line.isTotal) Divider(color: scheme.outlineVariant),
            FinanceFigureRow(
              label: line.label,
              value: line.label == 'المرتجعات المنفذة'
                  ? '− ${FinanceFormat.moneyPrecise(line.amount)}'
                  : FinanceFormat.moneyPrecise(line.amount),
              emphasised: line.isTotal || line.isSubtotal,
              valueColor: line.isTotal
                  ? palette.positive
                  : line.label == 'المرتجعات المنفذة'
                  ? palette.negative
                  : null,
            ),
          ],
          const SizedBox(height: AppSpacing.small),
          Container(
            padding: const EdgeInsets.all(AppSpacing.medium),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withAlpha(70),
              borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'بنود خارج الصافي',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                for (final line in memoLines)
                  FinanceFigureRow(
                    label: line.label,
                    value: FinanceFormat.moneyPrecise(line.amount),
                    muted: true,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodTable extends StatelessWidget {
  final FinanceAnalytics analytics;

  const _MethodTable({required this.analytics});

  @override
  Widget build(BuildContext context) {
    if (analytics.byMethod.isEmpty) {
      return Text(
        'لا توجد عمليات محصّلة في هذه الفترة.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Column(
      children: [
        FinanceRankedList(
          rows: analytics.byMethod,
          total: analytics.netRevenue,
          limit: FinancePaymentMethod.values.length,
        ),
        const Divider(height: AppSpacing.large),
        FinanceFigureRow(
          label: 'الإجمالي',
          value: FinanceFormat.moneyPrecise(analytics.netRevenue),
          trailing: '${FinanceFormat.count(analytics.paidCount)} عملية',
          emphasised: true,
        ),
      ],
    );
  }
}

class _RefundRequestsSummary extends StatelessWidget {
  final FinanceLoaded state;

  const _RefundRequestsSummary({required this.state});

  @override
  Widget build(BuildContext context) {
    final palette = DashboardChartPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final pending = state.pendingRefundRequests;

    if (state.refundRequests.isEmpty) {
      return Text(
        'لا توجد طلبات استرداد مسجلة.',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      );
    }

    final byStatus = <RefundStatus, ({int count, double amount})>{};
    for (final request in state.refundRequests) {
      final current = byStatus[request.status] ?? (count: 0, amount: 0.0);
      byStatus[request.status] = (
        count: current.count + 1,
        amount: current.amount + request.amount,
      );
    }

    return Column(
      children: [
        for (final status in RefundStatus.values)
          if (byStatus[status] != null)
            FinanceFigureRow(
              label: status.label,
              value: FinanceFormat.money(byStatus[status]!.amount),
              trailing: '${FinanceFormat.count(byStatus[status]!.count)} طلب',
              valueColor: status == RefundStatus.pending
                  ? palette.warning
                  : null,
            ),
        if (pending.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.small),
          Container(
            padding: const EdgeInsets.all(AppSpacing.medium),
            decoration: BoxDecoration(
              color: palette.warning.withAlpha(22),
              borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
              border: Border.all(color: palette.warning.withAlpha(60)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: palette.warning,
                ),
                const SizedBox(width: AppSpacing.small),
                Expanded(
                  child: Text(
                    '${FinanceFormat.count(pending.length)} طلب استرداد بقيمة ${FinanceFormat.money(state.pendingRefundAmount)} ما زالت بانتظار القرار، ولم تُخصم بعد من صافي الإيراد.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _DailyTable extends StatelessWidget {
  final FinanceAnalytics analytics;

  const _DailyTable({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final palette = DashboardChartPalette.of(context);
    // Newest first: a finance reader opens this to check yesterday, not the
    // first day of the quarter.
    final rows = analytics.daily.reversed.toList();

    return OpsDataTable(
      columns: const [
        OpsColumn('التاريخ', flex: 3, minWidth: 130),
        OpsColumn('عدد المعاملات', flex: 2, numeric: true, minWidth: 120),
        OpsColumn('صافي المحصّل', flex: 3, numeric: true, minWidth: 140),
        OpsColumn('مرتجعات', flex: 2, numeric: true, minWidth: 120),
        OpsColumn('قيد التحصيل', flex: 2, numeric: true, minWidth: 130),
      ],
      rows: [
        for (final point in rows)
          [
            Text(FinanceFormat.date(point.date)),
            Text(FinanceFormat.count(point.transactions)),
            Text(
              FinanceFormat.money(point.net),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            Text(
              point.refunded > 0 ? FinanceFormat.money(point.refunded) : '—',
              style: TextStyle(
                color: point.refunded > 0 ? palette.negative : null,
              ),
            ),
            Text(point.pending > 0 ? FinanceFormat.money(point.pending) : '—'),
          ],
      ],
      total: rows.length,
      currentPage: 0,
      pageSize: rows.isEmpty ? 1 : rows.length,
      onPageChanged: (_) {},
      emptyLabel: 'لا توجد حركة مالية في هذه الفترة',
    );
  }
}
