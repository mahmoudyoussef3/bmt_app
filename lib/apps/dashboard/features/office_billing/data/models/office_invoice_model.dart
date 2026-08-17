import '../../domain/entities/office_invoice.dart';

class OfficeInvoiceModel extends OfficeInvoice {
  const OfficeInvoiceModel({
    required super.id,
    required super.invoiceNumber,
    required super.total,
    required super.status,
    super.currency,
    super.periodStart,
    super.periodEnd,
    super.issuedAt,
    super.dueAt,
    super.paidAt,
    super.lineItems,
  });

  factory OfficeInvoiceModel.fromJson(Map<String, dynamic> json) {
    DateTime? at(String key) => DateTime.tryParse((json[key] as String?) ?? '');
    return OfficeInvoiceModel(
      id: json['id'] as String,
      invoiceNumber: (json['invoice_number'] as String?) ?? '',
      total: (json['total'] as num?) ?? 0,
      currency: (json['currency'] as String?) ?? 'EGP',
      status: (json['status'] as String?) ?? 'issued',
      periodStart: at('period_start'),
      periodEnd: at('period_end'),
      issuedAt: at('issued_at'),
      dueAt: at('due_at'),
      paidAt: at('paid_at'),
      lineItems: [
        for (final item in (json['line_items'] as List?) ?? const [])
          Map<String, dynamic>.from(item as Map),
      ],
    );
  }
}
