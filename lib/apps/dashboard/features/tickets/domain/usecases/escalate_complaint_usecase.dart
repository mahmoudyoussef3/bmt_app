import '../entities/complaint.dart';
import '../repositories/tickets_repository.dart';

class EscalateComplaintUseCase {
  final TicketsRepository _repository;

  const EscalateComplaintUseCase(this._repository);

  Future<Complaint> call(String id) => _repository.escalateComplaint(id);
}
