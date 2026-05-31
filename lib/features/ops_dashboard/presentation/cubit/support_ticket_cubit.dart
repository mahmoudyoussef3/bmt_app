import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/support_ticket.dart';
import '../../domain/repositories/support_ticket_repository.dart';
import 'support_ticket_state.dart';

class SupportTicketCubit extends Cubit<SupportTicketState> {
  final SupportTicketRepository repository;

  SupportTicketCubit(this.repository) : super(SupportTicketLoading());

  Future<void> loadTickets() async {
    try {
      emit(SupportTicketLoading());
      final tickets = await repository.fetchTickets(limit: 100);
      emit(SupportTicketLoaded(tickets));
    } catch (e) {
      emit(SupportTicketError(e.toString()));
    }
  }

  Future<void> loadTicketsFiltered({
    TicketStatus? status,
    String? search,
  }) async {
    try {
      emit(SupportTicketLoading());
      var tickets = await repository.fetchTickets(limit: 200);
      if (status != null)
        tickets = tickets.where((t) => t.status == status).toList();
      if (search != null && search.isNotEmpty) {
        final q = search.toLowerCase();
        tickets = tickets
            .where(
              (t) =>
                  t.id.toLowerCase().contains(q) ||
                  t.customerId.toLowerCase().contains(q) ||
                  t.subject.toLowerCase().contains(q),
            )
            .toList();
      }
      emit(
        SupportTicketLoaded(tickets, filterStatus: status, searchQuery: search),
      );
    } catch (e) {
      emit(SupportTicketError(e.toString()));
    }
  }

  Future<void> assignAgent(String ticketId, String agentId) async {
    final t = await repository.getTicket(ticketId);
    final updated = SupportTicket(
      id: t.id,
      customerId: t.customerId,
      subject: t.subject,
      description: t.description,
      status: t.status,
      priority: t.priority,
      createdAt: t.createdAt,
      updatedAt: DateTime.now(),
      attachments: t.attachments,
      assignedAgentId: agentId,
      internalNotes: t.internalNotes,
    );
    await repository.updateTicket(updated);
    await loadTickets();
  }

  Future<void> changeStatus(String ticketId, TicketStatus status) async {
    final t = await repository.getTicket(ticketId);
    final updated = SupportTicket(
      id: t.id,
      customerId: t.customerId,
      subject: t.subject,
      description: t.description,
      status: status,
      priority: t.priority,
      createdAt: t.createdAt,
      updatedAt: DateTime.now(),
      attachments: t.attachments,
      assignedAgentId: t.assignedAgentId,
      internalNotes: t.internalNotes,
    );
    await repository.updateTicket(updated);
    await loadTickets();
  }

  Future<void> addNote(String ticketId, String agentId, String note) async {
    await repository.addInternalNote(ticketId, agentId, note);
    await loadTickets();
  }

  Future<void> addInternalNote(
    String ticketId,
    String agentId,
    String note,
  ) async {
    await repository.addInternalNote(ticketId, agentId, note);
    await loadTickets();
  }
}
