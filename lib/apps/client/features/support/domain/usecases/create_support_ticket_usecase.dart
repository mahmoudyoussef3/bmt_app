import '../repositories/support_repository.dart';
import '../entities/support_ticket.dart';

class CreateSupportTicketUseCase {
  final SupportRepository _repository;

  const CreateSupportTicketUseCase(this._repository);

  Future<SupportTicket> call({
    required String category,
    required String title,
    required String description,
    String? relatedBookingId,
    String? relatedTripId,
  }) {
    return _repository.createTicket(
      category: category,
      title: title,
      description: description,
      relatedBookingId: relatedBookingId,
      relatedTripId: relatedTripId,
    );
  }
}
