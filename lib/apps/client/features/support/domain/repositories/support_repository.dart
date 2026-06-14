import 'dart:io';
import '../entities/support_ticket.dart';
import '../entities/support_message.dart';
import '../entities/support_attachment.dart';
import '../entities/support_refund_request.dart';
import '../entities/support_timeline_event.dart';
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
  
  Future<List<SupportMessage>> getTicketMessages(String ticketId);
  
  Future<List<SupportTimelineEvent>> getTicketTimeline(String ticketId);

  Future<SupportMessage> sendTicketMessage({
    required String ticketId,
    required String message,
  });

  Future<SupportAttachment> uploadAttachment({
    required String ticketId,
    String? messageId,
    required File file,
  });

  Future<SupportRefundRequest> createRefundRequest({
    required String reason,
    String? description,
    required double amount,
    String? bookingId,
    String? tripId,
    File? evidenceFile,
  });

  Stream<List<SupportMessage>> subscribeToMessages(String ticketId);
  
  Stream<SupportTicket> subscribeToTicketUpdates(String ticketId);
}
