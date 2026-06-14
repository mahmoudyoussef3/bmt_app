import '../entities/support_timeline_event.dart';
import '../repositories/support_repository.dart';

class GetTicketTimelineUseCase {
  final SupportRepository _repository;

  GetTicketTimelineUseCase(this._repository);

  Future<List<SupportTimelineEvent>> call(String ticketId) {
    return _repository.getTicketTimeline(ticketId);
  }
}
