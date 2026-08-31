import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';

import '../../../../core/theme/dashboard_colors.dart';
import '../../../../core/theme/dashboard_icons.dart';
import '../../../platform_licensing/presentation/widgets/licensing_widgets.dart';
import '../../domain/entities/office_invoice.dart';

/// One invoice, opened from its row.
///
/// `line_items` is where add-ons, overage, proration and coupons land, and this
/// is the first surface on either side of the platform that renders it. Every
/// field is read defensively: the column is free-form `jsonb`, seeded with
/// `{type, label, qty, unit, amount}` but written by whatever issued the
/// invoice.
Future<void> showOfficeInvoiceDetail(
  BuildContext context,
  OfficeInvoice invoice,
) {
  return showDialog<void>(
    context: context,
    builder: (context) => _OfficeInvoiceDetailDialog(invoice: invoice),
  );
}

class _OfficeInvoiceDetailDialog extends StatelessWidget {
  const _OfficeInvoiceDetailDialog({required this.invoice});

  final OfficeInvoice invoice;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            DashboardIcons.billing,
            size: 20,
            color: DashboardColors.mutedInk(context),
          ),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Text(
              invoice.invoiceNumber,
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
          InvoiceStatusChip(
            status: invoice.status,
            label: invoice.statusLabelAr,
          ),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LicensingField(
                label: 'الفترة',
                value: invoice.periodStart == null && invoice.periodEnd == null
                    ? '—'
                    : 'من ${licensingDate(invoice.periodStart)} '
                          'إلى ${licensingDate(invoice.periodEnd)}',
              ),
              LicensingField(
                label: 'تاريخ الإصدار',
                value: licensingDate(invoice.issuedAt),
              ),
              LicensingField(
                label: 'تاريخ الاستحقاق',
                value: licensingDate(invoice.dueAt),
              ),
              if (invoice.paidAt != null)
                LicensingField(
                  label: 'تاريخ السداد',
                  value: licensingDate(invoice.paidAt),
                ),
              const SizedBox(height: AppSpacing.medium),
              _LineItems(invoice: invoice),
              const SizedBox(height: AppSpacing.medium),
              Text(
                'وسيلة السداد ومن سجّلها بيانات داخلية لدى المنصة ولا تظهر هنا. '
                'لطلب نسخة رسمية من الفاتورة تواصل مع إدارة المنصة.',
                style: text.labelSmall?.copyWith(
                  color: DashboardColors.mutedInk(context),
                  height: 1.7,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إغلاق'),
        ),
      ],
    );
  }
}

class _LineItems extends StatelessWidget {
  const _LineItems({required this.invoice});

  final OfficeInvoice invoice;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final items = invoice.lineItems;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: DashboardColors.well(context),
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: DashboardColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'البنود',
            style: text.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.small),
          if (items.isEmpty)
            Text(
              'لا توجد بنود مفصّلة على هذه الفاتورة.',
              style: text.bodySmall?.copyWith(
                color: DashboardColors.mutedInk(context),
              ),
            )
          else
            for (final item in items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _label(item),
                            style: text.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (_quantity(item) != null)
                            Text(
                              _quantity(item)!,
                              style: text.labelSmall?.copyWith(
                                color: DashboardColors.mutedInk(context),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.small),
                    Text(
                      licensingMoney(
                        (item['amount'] as num?),
                        invoice.currency,
                      ),
                      style: text.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
          Divider(
            height: AppSpacing.large,
            color: DashboardColors.divider(context),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  'الإجمالي',
                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                licensingMoney(invoice.total, invoice.currency),
                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _label(Map<String, dynamic> item) {
    final label = (item['label'] as String?)?.trim();
    if (label != null && label.isNotEmpty) return label;
    final type = (item['type'] as String?)?.trim();
    return type == null || type.isEmpty ? 'بند' : type;
  }

  /// «٢ × ٤٠٠ ج.م» — only when the invoice actually carries both, since a
  /// single-line plan charge has no quantity worth stating.
  static String? _quantity(Map<String, dynamic> item) {
    final qty = item['qty'] as num?;
    final unit = item['unit'] as num?;
    if (qty == null || unit == null) return null;
    if (qty == 1) return null;
    return '$qty × ${licensingMoney(unit)}';
  }
}
