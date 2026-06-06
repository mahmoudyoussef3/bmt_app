import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/conversation.dart';
import '../../domain/usecases/get_conversation_usecase.dart';
import '../../domain/usecases/send_message_usecase.dart';
import 'communication_state.dart';

class CaptainCommunicationCubit extends Cubit<CaptainCommunicationState> {
  CaptainCommunicationCubit({
    required GetConversationUseCase getConversation,
    required SendMessageUseCase sendMessage,
  }) : _getConversation = getConversation,
       _sendMessage = sendMessage,
       super(const CaptainCommunicationLoading());

  final GetConversationUseCase _getConversation;
  final SendMessageUseCase _sendMessage;

  String? _tripId;
  String? _passengerId;

  Future<void> load({required String tripId, String? passengerId}) async {
    _tripId = tripId;
    _passengerId = passengerId;
    emit(const CaptainCommunicationLoading());
    try {
      emit(
        CaptainCommunicationLoaded(
          await _getConversation(tripId: tripId, passengerId: passengerId),
        ),
      );
    } catch (error) {
      emit(CaptainCommunicationError(error.toString()));
    }
  }

  Future<void> send(String text, CaptainMessageType type) async {
    final tripId = _tripId;
    if (tripId == null || text.trim().isEmpty) return;
    try {
      emit(
        CaptainCommunicationLoaded(
          await _sendMessage(
            tripId: tripId,
            passengerId: _passengerId,
            text: text.trim(),
            type: type,
          ),
        ),
      );
    } catch (error) {
      emit(CaptainCommunicationError(error.toString()));
    }
  }
}
