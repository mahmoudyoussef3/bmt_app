import '../entities/complaint.dart';
import '../repositories/tickets_repository.dart';

class MarkCustomerContactedUseCase {
  final TicketsRepository _repository;

  const MarkCustomerContactedUseCase(this._repository);

  Future<SupportTicket> call(String id) {
    return _repository.markCustomerContacted(id);
  }
}
