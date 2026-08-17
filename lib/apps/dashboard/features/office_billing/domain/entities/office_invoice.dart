/// An invoice as the OFFICE sees it: its own history, and nothing about any
/// other tenant.
///
/// Deliberately thinner than the platform-side `PlatformInvoice`: no office
/// reference (it is always this office), no `recorded_by`, no internal notes.
/// The office reads its licence and its invoices; it does not read the
/// platform's decision trail (§17.7).
class OfficeInvoice {
  const OfficeInvoice({
    required this.id,
    required this.invoiceNumber,
    required this.total,
    required this.status,
    this.currency = 'EGP',
    this.periodStart,
    this.periodEnd,
    this.issuedAt,
    this.dueAt,
    this.paidAt,
    this.lineItems = const [],
  });

  final String id;
  final String invoiceNumber;
  final num total;
  final String currency;

  /// `issued` | `paid` | `overdue` | `void` | `refunded`. Drafts never reach an
  /// office — the RPC filters them out.
  final String status;

  final DateTime? periodStart;
  final DateTime? periodEnd;
  final DateTime? issuedAt;
  final DateTime? dueAt;
  final DateTime? paidAt;
  final List<Map<String, dynamic>> lineItems;

  bool get isPaid => status == 'paid';
  bool get isOverdue => status == 'overdue';

  String get statusLabelAr => switch (status) {
    'issued' => 'صادرة',
    'paid' => 'مسددة',
    'overdue' => 'متأخرة',
    'void' => 'ملغاة',
    'refunded' => 'مستردة',
    _ => status,
  };
}
