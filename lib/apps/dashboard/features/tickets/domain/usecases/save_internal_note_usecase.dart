import '../entities/complaint.dart';
import '../repositories/tickets_repository.dart';

class SaveInternalNoteUseCase {
  final TicketsRepository _repository;

  const SaveInternalNoteUseCase(this._repository);

  Future<SupportTicket> call(String id, String note) {
    return _repository.saveInternalNote(id, note);
  }
}
