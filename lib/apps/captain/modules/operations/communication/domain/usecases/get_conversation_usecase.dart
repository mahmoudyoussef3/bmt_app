import '../entities/conversation.dart';
import '../repositories/communication_repository.dart';

class GetConversationUseCase {
  const GetConversationUseCase(this._repository);

  final CommunicationRepository _repository;

  Future<CaptainConversation> call({
    required String tripId,
    String? passengerId,
  }) {
    return _repository.getConversation(
      tripId: tripId,
      passengerId: passengerId,
    );
  }
}
