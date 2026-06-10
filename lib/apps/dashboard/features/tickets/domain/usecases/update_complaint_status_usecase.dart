import '../entities/complaint.dart';
import '../repositories/tickets_repository.dart';

class UpdateComplaintStatusUseCase {
  final TicketsRepository _repository;

  const UpdateComplaintStatusUseCase(this._repository);

  Future<Complaint> call(String id, ComplaintStatus status) =>
      _repository.updateComplaintStatus(id, status);
}
