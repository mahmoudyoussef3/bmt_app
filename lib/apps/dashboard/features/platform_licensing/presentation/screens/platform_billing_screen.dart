import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

import '../../../../core/theme/dashboard_colors.dart';
import '../../../../core/theme/dashboard_icons.dart';
import '../../../../core/widgets/dashboard_empty_state.dart';
import '../../../../core/widgets/dashboard_kpi_card.dart';
import '../../../../core/widgets/dashboard_module_header.dart';
import '../../../../core/widgets/dashboard_panel.dart';
import '../../../../core/widgets/ops_data_table.dart';
import '../../domain/entities/office_license.dart';
import '../cubit/platform_licensing_cubit.dart';
import '../widgets/licensing_scaffold.dart';
import '../widgets/licensing_widgets.dart';

/// الفوترة — the platform billing its offices.
///
/// Records only. There is no gateway, no card capture and no automatic
/// collection in V1: an invoice here is a record a gateway later plugs into,
/// and payment is recorded by hand when it arrives. Saying so on the screen is
/// what stops someone assuming a "paid" chip means money moved by itself.
class PlatformBillingScreen extends StatefulWidget {
  const PlatformBillingScreen({super.key});

  @override
  State<PlatformBillingScreen> createState() => _PlatformBillingScreenState();
}

class _PlatformBillingScreenState extends State<PlatformBillingScreen> {
  int _page = 0;
  static const _pageSize = 15;

  @override
  Widget build(BuildContext context) {
    return LicensingScreenFrame(
      builder: (context, state) {
        final cubit = context.read<PlatformLicensingCubit>();
        final billing = state.billing;
        final invoices = billing.invoices;
        final pageRows = invoices
            .skip(_page * _pageSize)
            .take(_pageSize)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DashboardModuleHeader(
              icon: DashboardIcons.billing,
              title: 'الفوترة',
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
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.medium),
                child: DashboardKpiGrid(
                  children: [
                    DashboardKpiCard(
                      label: 'إيراد شهري متكرر',
                      value: licensingMoney(billing.mrr),
                      icon: DashboardIcons.revenue,
                      detail: 'من التراخيص النشطة فقط',
                    ),
                    DashboardKpiCard(
                      label: 'مسدَّد',
                      value: licensingMoney(billing.paid),
                      icon: DashboardIcons.allClear,
                    ),
                    DashboardKpiCard(
                      label: 'صادر وغير مسدَّد',
                      value: licensingMoney(billing.issued),
                      icon: DashboardIcons.payments,
                    ),
                    DashboardKpiCard(
                      label: 'متأخر',
                      value: licensingMoney(billing.overdue),
                      icon: DashboardIcons.attention,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            if (billing.renewals.isNotEmpty) ...[
              DashboardPanel(
                icon: DashboardIcons.time,
                title: 'تجديدات خلال ٣٠ يومًا',
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
                icon: DashboardIcons.billing,
                title: 'الفواتير',
                subtitle: '${billing.invoiceCount} فاتورة',
                child: invoices.isEmpty
                    ? const DashboardEmptyState(
                        icon: DashboardIcons.billing,
                        title: 'لا توجد فواتير بعد',
                        message:
                            'تصدر الفواتير مع التجديد الدوري أو يدويًا من شاشة '
                            'الترخيص.',
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
      },
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
          'اكتب طريقة السداد كما وصلت فعلًا (تحويل بنكي، نقدًا، …). التسجيل '
          'يرفع أي تقييد ناتج عن التأخر.',
      confirmLabel: 'تسجيل',
      minLength: 3,
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
    );
    if (reason == null || !context.mounted) return;
    await cubit.voidInvoice(invoice.id, reason);
  }
}
