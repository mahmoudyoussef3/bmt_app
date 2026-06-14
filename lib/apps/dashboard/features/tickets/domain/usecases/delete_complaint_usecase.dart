import '../repositories/tickets_repository.dart';

class DeleteComplaintUseCase {
  final TicketsRepository _repository;

  const DeleteComplaintUseCase(this._repository);

  Future<void> call(String id) async {
    return await _repository.deleteComplaint(id);
  }
}
