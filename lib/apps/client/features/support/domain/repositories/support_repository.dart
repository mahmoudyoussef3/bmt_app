import 'dart:io';
import '../entities/related_booking_option.dart';
import '../entities/support_office_option.dart';
import '../entities/support_ticket.dart';
import '../entities/support_attachment.dart';

abstract class SupportRepository {
  Future<List<SupportTicket>> getMyTickets();

  Future<List<RelatedBookingOption>> getRelatedBookingOptions();

  Future<List<SupportOfficeOption>> getOfficeOptions();

  Future<SupportTicket> createTicket({
    required String category,
    required String title,
    required String description,
    String? officeId,
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
