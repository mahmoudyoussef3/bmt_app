import '../entities/complaint.dart';
import '../repositories/tickets_repository.dart';

class GetComplaintsUseCase {
  final TicketsRepository _repository;

  const GetComplaintsUseCase(this._repository);

  Future<List<Complaint>> call() => _repository.getComplaints();
}
