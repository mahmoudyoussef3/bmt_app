import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';

import '../../../../core/theme/dashboard_colors.dart';
import '../../../../core/theme/dashboard_icons.dart';
import '../../../../core/widgets/dashboard_cap_notice.dart';
import '../../../../core/widgets/dashboard_empty_state.dart';
import '../../../../core/widgets/dashboard_queue_tabs.dart';
import '../../../../core/widgets/dashboard_results_header.dart';
import '../../../../core/widgets/ops_data_table.dart';
import '../../../platform_licensing/presentation/widgets/licensing_widgets.dart';
import '../../domain/entities/office_invoice.dart';
import '../cubit/office_billing_cubit.dart';
import '../models/office_invoice_view.dart';
import 'office_invoice_detail_dialog.dart';

/// الفواتير — the office's own billing history.
///
/// It was a `Column` of dense `ListTile`s with no filter, no pager and no
/// detail, over a fetch of the first 50 rows: an office trading for four years
/// could not reach its first year, and `line_items` — where add-ons, overage,
/// proration and coupons all land — was parsed on every row and thrown away.
///
/// Now the console's own table shape, the same one every other financial list
/// uses, with the three questions an office asks as queue tabs and the row
/// opening the invoice.
class OfficeInvoicesPanel extends StatefulWidget {
  const OfficeInvoicesPanel({
    super.key,
    required this.invoices,
    required this.onRetry,
    this.error,
    this.isLoading = false,
  });

  final List<OfficeInvoice> invoices;

  /// Retries the invoice half alone — the plan and the meters above it are
  /// still true and must not be torn down to re-ask this question.
  final VoidCallback onRetry;

  final String? error;
  final bool isLoading;

  @override
  State<OfficeInvoicesPanel> createState() => _OfficeInvoicesPanelState();
}

class _OfficeInvoicesPanelState extends State<OfficeInvoicesPanel> {
  OfficeInvoiceFilter _filter = OfficeInvoiceFilter.all;
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.error != null) {
      return _InvoicesError(message: widget.error!, onRetry: widget.onRetry);
    }

    if (widget.invoices.isEmpty) {
      return DashboardEmptyState(
        icon: DashboardIcons.billing,
        title: 'لا توجد فواتير',
        message: 'لم تصدر أي فاتورة اشتراك لهذا المكتب بعد.',
        action: widget.isLoading
            ? null
            : TextButton.icon(
                onPressed: widget.onRetry,
                icon: const Icon(DashboardIcons.refresh, size: 18),
                label: const Text('تحديث'),
              ),
      );
    }

    final rows = widget.invoices.where(_filter.matches).toList(growable: false);

    // A filter that shortens the list must not leave the table on a page that
    // no longer exists — the pager would then render an empty table over a
    // non-zero total, which reads as data loss.
    final pages = officeInvoicePageCount(rows.length);
    final page = _page >= pages ? pages - 1 : _page;
    final visible = officeInvoicePage(rows, page);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DashboardQueueTabBar(
          tabs: [
            for (final filter in OfficeInvoiceFilter.values)
              DashboardQueueTab(
                label: filter.label,
                count: '${widget.invoices.where(filter.matches).length}',
                selected: _filter == filter,
                urgent: filter.isUrgent,
                onTap: () => setState(() {
                  _filter = filter;
                  _page = 0;
                }),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.medium),
        DashboardResultsHeader(
          icon: DashboardIcons.billing,
          title: _filter.label == 'الكل' ? 'كل الفواتير' : _filter.label,
          subtitle: rows.isEmpty
              ? 'لا توجد فواتير في هذا التبويب'
              : 'عرض ${visible.isEmpty ? 0 : page * officeInvoicePageSize + 1}'
                    '–${page * officeInvoicePageSize + visible.length} '
                    'من ${rows.length}',
        ),
        const SizedBox(height: AppSpacing.small),
        OpsDataTable(
          columns: const [
            OpsColumn('رقم الفاتورة', flex: 3, minWidth: 130),
            OpsColumn('الفترة', flex: 4, minWidth: 190),
            OpsColumn('الاستحقاق', flex: 3, minWidth: 110),
            OpsColumn('القيمة', flex: 3, numeric: true, minWidth: 110),
            OpsColumn('الحالة', flex: 2, minWidth: 96),
          ],
          rows: [for (final invoice in visible) _cells(context, invoice)],
          rowTints: [
            for (final invoice in visible)
              invoice.isOverdue
                  ? context.status(AppStatusTone.error).tint
                  : null,
          ],
          onRowTap: [
            for (final invoice in visible)
              () => showOfficeInvoiceDetail(context, invoice),
          ],
          total: rows.length,
          currentPage: page,
          pageSize: officeInvoicePageSize,
          onPageChanged: (next) => setState(() => _page = next),
          totalLabel: 'الإجمالي ${rows.length} فاتورة',
          emptyState: DashboardEmptyState(
            icon: DashboardIcons.billing,
            title: 'لا توجد فواتير في «${_filter.label}»',
            message: 'جرّب تبويب «الكل» لرؤية كل ما صدر لمكتبك.',
          ),
        ),
        if (widget.invoices.length >= officeInvoiceWindow) ...[
          const SizedBox(height: AppSpacing.small),
          const DashboardCapNotice(
            rowCap: officeInvoiceWindow,
            noun: 'فاتورة',
            hint: 'لطلب سجل أقدم، تواصل مع إدارة المنصة.',
          ),
        ],
        const SizedBox(height: AppSpacing.small),
        Text(
          'اضغط أي صف لعرض بنود الفاتورة. الفواتير المسوّدة لا تصل المكتب.',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: DashboardColors.mutedInk(context),
          ),
        ),
      ],
    );
  }

  List<Widget> _cells(BuildContext context, OfficeInvoice invoice) {
    final text = Theme.of(context).textTheme;
    final muted = text.bodySmall?.copyWith(
      color: DashboardColors.mutedInk(context),
    );

    return [
      Text(
        invoice.invoiceNumber,
        style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        overflow: TextOverflow.ellipsis,
      ),
      Text(
        invoice.periodStart == null && invoice.periodEnd == null
            ? '—'
            : 'من ${licensingDate(invoice.periodStart)} '
                  'إلى ${licensingDate(invoice.periodEnd)}',
        style: muted,
        overflow: TextOverflow.ellipsis,
      ),
      Text(
        licensingDate(invoice.dueAt),
        style: invoice.isOverdue
            ? text.bodySmall?.copyWith(
                color: context.status(AppStatusTone.error).accent,
                fontWeight: FontWeight.w700,
              )
            : muted,
      ),
      Text(
        licensingMoney(invoice.total, invoice.currency),
        style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: InvoiceStatusChip(
          status: invoice.status,
          label: invoice.statusLabelAr,
        ),
      ),
    ];
  }
}

/// The invoice fetch failed on its own. Everything above this panel loaded, so
/// this is a notice with a retry — not the screen's error state.
class _InvoicesError extends StatelessWidget {
  const _InvoicesError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final status = context.status(AppStatusTone.error);
    final text = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: status.tint,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: status.accent.withAlpha(60)),
      ),
      child: Wrap(
        spacing: AppSpacing.medium,
        runSpacing: AppSpacing.small,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(DashboardIcons.attention, size: 18, color: status.ink),
              const SizedBox(width: AppSpacing.small),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Text(
                  message,
                  style: text.bodySmall?.copyWith(color: status.ink),
                ),
              ),
            ],
          ),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(DashboardIcons.refresh, size: 18),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }
}
