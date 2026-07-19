import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_conversations_usecase.dart';
import '../models/conversation_filter.dart';
import 'communication_state.dart';

/// Drives the conversation list: loading it, and the search/filter the client
/// narrows it with. The open thread is owned by `ChatThreadCubit`.
class CommunicationCubit extends Cubit<CommunicationState> {
  CommunicationCubit(this._getConversations)
    : super(const CommunicationLoading());

  final GetConversationsUseCase _getConversations;

  Future<void> load() async {
    emit(const CommunicationLoading());
    try {
      final conversations = await _getConversations();
      if (isClosed) return;
      emit(CommunicationLoaded(conversations: conversations));
    } catch (error) {
      if (isClosed) return;
      emit(CommunicationError(error.toString()));
    }
  }

  /// Re-reads the list in place — no spinner, and the current list survives a
  /// failed refresh. Used when returning from a thread, whose newest message
  /// the list preview would otherwise miss.
  Future<void> refresh() async {
    final current = state;
    if (current is! CommunicationLoaded) return;
    try {
      final conversations = await _getConversations();
      if (isClosed) return;
      emit(current.copyWith(conversations: conversations));
    } catch (_) {
      // Keep showing the list already on screen.
    }
  }

  void setQuery(String query) {
    final current = state;
    if (current is! CommunicationLoaded) return;
    emit(current.copyWith(query: query));
  }

  void setFilter(ConversationFilter filter) {
    final current = state;
    if (current is! CommunicationLoaded) return;
    emit(current.copyWith(filter: filter));
  }
}
