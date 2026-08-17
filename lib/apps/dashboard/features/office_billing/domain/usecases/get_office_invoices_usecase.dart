import '../entities/office_invoice.dart';
import '../repositories/office_billing_repository.dart';

class GetOfficeInvoicesUseCase {
  const GetOfficeInvoicesUseCase(this._repository);

  final OfficeBillingRepository _repository;

  Future<List<OfficeInvoice>> call({int limit = 50, int offset = 0}) =>
      _repository.getInvoices(limit: limit, offset: offset);
}
