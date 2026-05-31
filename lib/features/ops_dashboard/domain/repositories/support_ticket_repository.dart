import '../models/support_ticket.dart';

abstract class SupportTicketRepository {
  Future<List<SupportTicket>> fetchTickets({
    TicketStatus? status,
    TicketPriority? priority,
    int limit,
    int offset,
  });

  Future<SupportTicket> getTicket(String id);

  Future<void> updateTicket(SupportTicket ticket);

  Future<void> createTicket(SupportTicket ticket);

  Future<void> addInternalNote(String ticketId, String agentId, String note);
}
