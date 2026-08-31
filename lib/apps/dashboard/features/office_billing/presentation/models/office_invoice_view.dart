import '../../domain/entities/office_invoice.dart';

/// The three questions an office asks of its own invoice history: *all of it*,
/// *what do I still owe*, and *what did I already pay*.
///
/// A status-by-status filter would have six members, five of which an office
/// never asks for by name (`void` and `refunded` are rare and terminal). The
/// tabs are the questions, and the status chip on the row still names the exact
/// state.
enum OfficeInvoiceFilter { all, outstanding, paid }

extension OfficeInvoiceFilterX on OfficeInvoiceFilter {
  String get label => switch (this) {
    OfficeInvoiceFilter.all => 'الكل',
    OfficeInvoiceFilter.outstanding => 'مستحقة',
    OfficeInvoiceFilter.paid => 'مسدَّدة',
  };

  /// «مستحقة» is the queue with work in it, so its badge raises its voice while
  /// the operator is looking at another tab.
  bool get isUrgent => this == OfficeInvoiceFilter.outstanding;

  bool matches(OfficeInvoice invoice) => switch (this) {
    OfficeInvoiceFilter.all => true,
    OfficeInvoiceFilter.outstanding =>
      invoice.status == 'issued' || invoice.status == 'overdue',
    OfficeInvoiceFilter.paid => invoice.status == 'paid',
  };
}

/// Rows per page. Eight keeps the table shorter than the panels above it, which
/// is the right proportion for a history that is consulted rather than worked.
const int officeInvoicePageSize = 8;

int officeInvoicePageCount(int total) =>
    total <= 0 ? 1 : (total / officeInvoicePageSize).ceil();

/// The rows on [page] (0-based), clamped so a filter change that shortens the
/// list cannot leave the table on a page that no longer exists.
List<OfficeInvoice> officeInvoicePage(List<OfficeInvoice> rows, int page) {
  final start = page * officeInvoicePageSize;
  if (start >= rows.length) return const [];
  final end = start + officeInvoicePageSize;
  return rows.sublist(start, end > rows.length ? rows.length : end);
}
