import '../entities/support_ticket.dart';
import '../repositories/support_repository.dart';

class CreateSupportTicketUseCase {
  const CreateSupportTicketUseCase(this._repository);

  final SupportRepository _repository;

  Future<SupportTicket> call({
    required String category,
    required String title,
    required String description,
    required String priority,
    required bool imageAttached,
  }) async {
    return _repository.createTicket({
      'category': category,
      'title': title,
      'description': description,
      'priority': priority,
      'imageAttached': imageAttached,
    });
  }
}
