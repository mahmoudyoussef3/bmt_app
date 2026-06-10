import '../entities/complaint.dart';
import '../repositories/tickets_repository.dart';

class CloseComplaintUseCase {
  final TicketsRepository _repository;

  const CloseComplaintUseCase(this._repository);

  Future<Complaint> call(String id) => _repository.closeComplaint(id);
}
