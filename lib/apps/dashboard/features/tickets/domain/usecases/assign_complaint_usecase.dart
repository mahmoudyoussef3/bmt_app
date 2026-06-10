import '../entities/complaint.dart';
import '../repositories/tickets_repository.dart';

class AssignComplaintUseCase {
  final TicketsRepository _repository;

  const AssignComplaintUseCase(this._repository);

  Future<Complaint> call(String id, String agentName) =>
      _repository.assignComplaint(id, agentName);
}
