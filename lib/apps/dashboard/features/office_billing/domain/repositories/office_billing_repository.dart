import '../entities/office_invoice.dart';

abstract class OfficeBillingRepository {
  /// The office's invoices, newest first.
  Future<List<OfficeInvoice>> getInvoices({int limit, int offset});
}
