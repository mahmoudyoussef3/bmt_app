import '../entities/complaint.dart';

abstract class TicketsRepository {
  Future<List<SupportTicket>> getTickets();

  Future<SupportTicket> updateTicketStatus(String id, TicketStatus status);

  Future<SupportTicket> saveInternalNote(String id, String note);

  Future<SupportTicket> markCustomerContacted(String id);

  Future<SupportTicket> closeTicket(String id);

  Future<List<SupportAttachment>> getTicketAttachments(String ticketId);

  Future<SupportTicket> assignAgent(
    String ticketId,
    String agentId,
    String agentName,
  );

  Future<List<Map<String, dynamic>>> getAgents();
}
