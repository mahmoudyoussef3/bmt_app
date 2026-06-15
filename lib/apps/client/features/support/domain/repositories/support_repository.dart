import 'dart:io';
import '../entities/support_ticket.dart';
import '../entities/support_attachment.dart';
import '../entities/support_workspace.dart';

abstract class SupportRepository {
  Future<SupportWorkspace> getWorkspace();
  
  Future<List<SupportTicket>> getMyTickets();
  
  Future<SupportTicket> createTicket({
    required String category,
    required String title,
    required String description,
    required String priority,
    String? relatedBookingId,
    String? relatedTripId,
  });

  Future<SupportTicket> getTicketDetails(String ticketId);
  
  Future<List<SupportAttachment>> getTicketAttachments(String ticketId);

  Future<SupportAttachment> uploadAttachment({
    required String ticketId,
    required File file,
  });
}
