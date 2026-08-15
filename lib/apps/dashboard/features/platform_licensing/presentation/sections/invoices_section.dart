import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

import '../../../../core/theme/dashboard_colors.dart';
import '../../../../core/theme/dashboard_icons.dart';
import '../../../../core/widgets/dashboard_collapsible_section.dart';
import '../../../../core/widgets/dashboard_empty_state.dart';
import '../../../../core/widgets/dashboard_panel.dart';
import '../../../../core/widgets/ops_data_table.dart';
import '../../domain/entities/office_license.dart';
import '../cubit/platform_licensing_cubit.dart';
import '../cubit/platform_licensing_state.dart';
import '../widgets/licensing_layout.dart';
import '../widgets/licensing_widgets.dart';

/// الفوترة — the platform billing its offices.
///
/// Records only. There is no gateway, no card capture and no automatic
/// collection in V1: an invoice here is a record a gateway later plugs into,
/// and payment is recorded by hand when it arrives. Saying so on the screen is
/// what stops someone assuming a "paid" chip means money moved by itself.
///
/// The four figures used to be [DashboardKpiCard]s — four boxes, each with a
/// border and a shadow, for four numbers nobody drills into. They are a stat
/// line now, the same one every other platform section uses, which is a third
/// of the page returned to the invoice table.
class InvoicesSection extends StatefulWidget {
  const InvoicesSection({super.key, required this.state, this.tabBar});

  final PlatformLicensingLoaded state;
  final Widget? tabBar;

  @override
  State<InvoicesSection> createState() => _InvoicesSectionState();
}

class _InvoicesSectionState extends State<InvoicesSection> {
  int _page = 0;
  static const _pageSize = 15;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cubit = context.read<PlatformLicensingCubit>();
    final billing = widget.state.billing;
    final invoices = billing.invoices;
    final pageRows = invoices.skip(_page * _pageSize).take(_pageSize).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LicensingConsoleHeader(
          icon: DashboardIcons.billing,
          title: 'الفوترة والسجل',
          subtitle:
              'فواتير اشتراك المكاتب في المنصة. التحصيل يدوي في هذا الإصدار: '
              'الفاتورة سجلّ، والسداد يُسجَّل عند وصوله.',
          actions: [
            TextButton.icon(
              onPressed: cubit.runBillingCycle,
              icon: const Icon(Icons.autorenew_rounded, size: 18),
              label: const Text('تشغيل دورة التجديد'),
            ),
          ],
          tabBar: widget.tabBar,
          stats: [
            LicensingStat(
              icon: DashboardIcons.revenue,
              value: licensingMoney(billing.mrr),
              label: 'إيراد شهري متكرر — من التراخيص النشطة',
            ),
            LicensingStat(
              icon: DashboardIcons.allClear,
              value: licensingMoney(billing.paid),
              label: 'مسدَّد',
              color: scheme.secondary,
            ),
            LicensingStat(
              icon: DashboardIcons.payments,
              value: licensingMoney(billing.issued),
              label: 'صادر وغير مسدَّد',
            ),
            LicensingStat(
              icon: DashboardIcons.attention,
              value: licensingMoney(billing.overdue),
              label: 'متأخر',
              color: billing.overdue > 0 ? scheme.error : null,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.medium),
        if (billing.renewals.isNotEmpty) ...[
          DashboardPanel(
            sectionId: DashboardSectionIds.platformBillingRenewals,
            icon: DashboardIcons.time,
            title: 'تجديدات خلال ٣٠ يومًا',
            subtitle: '${billing.renewals.length} تجديد قادم',
            collapsedSummary: DashboardSectionSummary(
              items: ['${billing.renewals.length} تجديد'],
            ),
            child: Column(
              children: [
                for (final renewal in billing.renewals)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text('${renewal['office_name']}'),
                    subtitle: Text(
                      '${renewal['plan_key']} · '
                      '${licensingDate(DateTime.tryParse('${renewal['period_end']}'))}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(licensingMoney(renewal['amount'] as num?)),
                        const SizedBox(width: AppSpacing.small),
                        StatusChip(
                          label: renewal['auto_renew'] == true
                              ? 'تلقائي'
                              : 'يدوي',
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.medium),
        ],
        Expanded(
          child: DashboardPanel(
            sectionId: DashboardSectionIds.platformBillingInvoices,
            icon: DashboardIcons.billing,
            title: 'الفواتير',
            subtitle: '${billing.invoiceCount} فاتورة',
            child: invoices.isEmpty
                ? const DashboardEmptyState(
                    icon: DashboardIcons.billing,
                    title: 'لا توجد فواتير بعد',
                    message:
                        'تصدر الفواتير مع التجديد الدوري، أو يدويًا من بطاقة '
                        'المكتب في شاشة التراخيص.',
                  )
                : OpsDataTable(
                    columns: const [
                      OpsColumn('رقم الفاتورة', flex: 2),
                      OpsColumn('المكتب', flex: 3),
                      OpsColumn('المدة', flex: 3),
                      OpsColumn('المبلغ', flex: 2, numeric: true),
                      OpsColumn('الحالة', flex: 2),
                      OpsColumn('', flex: 2),
                    ],
                    rows: [
                      for (final invoice in pageRows)
                        _row(context, cubit, invoice),
                    ],
                    total: invoices.length,
                    currentPage: _page,
                    pageSize: _pageSize,
                    onPageChanged: (page) => setState(() => _page = page),
                  ),
          ),
        ),
      ],
    );
  }

  List<Widget> _row(
    BuildContext context,
    PlatformLicensingCubit cubit,
    PlatformInvoice invoice,
  ) {
    final text = Theme.of(context).textTheme;
    return [
      Text(invoice.invoiceNumber, style: text.bodySmall),
      Text(invoice.officeName ?? '—', style: text.bodySmall),
      Text(
        '${licensingDate(invoice.periodStart)} → ${licensingDate(invoice.periodEnd)}',
        style: text.bodySmall?.copyWith(
          color: DashboardColors.mutedInk(context),
        ),
      ),
      Text(
        licensingMoney(invoice.total, invoice.currency),
        style: text.bodySmall?.copyWith(fontWeight: FontWeight.bold),
      ),
      StatusChip(label: invoice.statusLabelAr),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (invoice.isPayable)
            TextButton(
              onPressed: () => _recordPayment(context, cubit, invoice),
              child: const Text('تسجيل سداد'),
            ),
          if (!invoice.isPaid && invoice.status != 'void')
            TextButton(
              onPressed: () => _void(context, cubit, invoice),
              child: const Text('إبطال'),
            ),
        ],
      ),
    ];
  }

  Future<void> _recordPayment(
    BuildContext context,
    PlatformLicensingCubit cubit,
    PlatformInvoice invoice,
  ) async {
    final method = await promptForReason(
      context,
      title: 'تسجيل سداد ${invoice.invoiceNumber}',
      description:
          'اكتب طريقة السداد كما وصلت فعلًا. التسجيل يرفع أي تقييد ناتج عن '
          'التأخر.',
      confirmLabel: 'تسجيل',
      minLength: 3,
      suggestions: const ['تحويل بنكي', 'نقدًا', 'محفظة إلكترونية', 'شيك'],
    );
    if (method == null || !context.mounted) return;
    await cubit.recordPayment(invoice.id, method, null);
  }

  Future<void> _void(
    BuildContext context,
    PlatformLicensingCubit cubit,
    PlatformInvoice invoice,
  ) async {
    final reason = await promptForReason(
      context,
      title: 'إبطال ${invoice.invoiceNumber}',
      description:
          'الإبطال يُخرج الفاتورة من الحسابات ويترك أثرًا في السجل. الفاتورة '
          'المسددة لا تُبطَل — عكس مبلغ محصَّل استرداد وليس تعديلًا.',
      confirmLabel: 'إبطال',
      suggestions: const [
        'صدرت بالخطأ على المكتب',
        'المبلغ غير صحيح وسيُعاد إصدارها',
        'أُلغي الاشتراك قبل بداية المدة',
      ],
    );
    if (reason == null || !context.mounted) return;
    await cubit.voidInvoice(invoice.id, reason);
  }
}
