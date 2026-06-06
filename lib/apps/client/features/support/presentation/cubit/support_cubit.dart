import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/support_ticket.dart';
import '../../domain/usecases/add_support_message_usecase.dart';
import '../../domain/usecases/create_support_ticket_usecase.dart';
import '../../domain/usecases/get_support_data_usecase.dart';
import 'support_state.dart';

class SupportCubit extends Cubit<SupportState> {
  SupportCubit({
    required GetSupportDataUseCase getSupportData,
    required CreateSupportTicketUseCase createTicket,
    required AddSupportMessageUseCase addMessage,
  }) : _getSupportData = getSupportData,
       _createTicket = createTicket,
       _addMessage = addMessage,
       super(const SupportLoading());

  final GetSupportDataUseCase _getSupportData;
  final CreateSupportTicketUseCase _createTicket;
  final AddSupportMessageUseCase _addMessage;

  Future<void> load() async {
    emit(const SupportLoading());
    try {
      final data = await _getSupportData();
      emit(SupportLoaded(categories: data.categories, tickets: data.tickets));
    } catch (error) {
      emit(SupportError(error.toString()));
    }
  }

  SupportTicket? createTicket({
    required String category,
    required String title,
    required String description,
    required String priority,
    required bool imageAttached,
  }) {
    final current = state;
    if (current is! SupportLoaded) return null;
    final ticket = _createTicket(
      category: category,
      title: title,
      description: description,
      priority: priority,
      imageAttached: imageAttached,
    );
    emit(current.copyWith(tickets: [ticket, ...current.tickets]));
    return ticket;
  }

  void openTicket(SupportTicket ticket) {
    final current = state;
    if (current is! SupportLoaded) return;
    emit(current.copyWith(activeTicketId: ticket.id));
  }

  void addUserMessage(String text) {
    final current = state;
    if (current is! SupportLoaded || current.activeTicket == null) return;
    final updated = _addMessage(
      ticket: current.activeTicket!,
      sender: 'user',
      text: text,
      time: 'Just now',
    );
    _replaceTicket(current, updated);
  }

  void addAgentReply(String ticketId) {
    final current = state;
    if (current is! SupportLoaded || current.activeTicket?.id != ticketId) {
      return;
    }
    final updated = _addMessage(
      ticket: current.activeTicket!,
      sender: 'agent',
      text:
          'Thank you for updating the ticket. An agent has been notified and is checking this.',
      time: '1 min ago',
    );
    _replaceTicket(current, updated);
  }

  void _replaceTicket(SupportLoaded current, SupportTicket updated) {
    final tickets = current.tickets
        .map((ticket) => ticket.id == updated.id ? updated : ticket)
        .toList();
    emit(current.copyWith(tickets: tickets, activeTicketId: updated.id));
  }
}
