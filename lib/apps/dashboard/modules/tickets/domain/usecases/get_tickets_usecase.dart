import '../entities/complaint.dart';
import '../repositories/tickets_repository.dart';

class GetTicketsUseCase {
  final TicketsRepository _repository;

  const GetTicketsUseCase(this._repository);

  Future<List<SupportTicket>> call() {
    return _repository.getTickets();
  }
}
