import 'dart:io';
import '../../domain/entities/support_ticket.dart';
import '../../domain/entities/support_message.dart';
import '../../domain/entities/support_attachment.dart';
import '../../domain/entities/support_refund_request.dart';
import '../../domain/entities/support_timeline_event.dart';
import '../../domain/entities/support_workspace.dart';
import '../../domain/repositories/support_repository.dart';
import '../datasources/supabase_support_datasource.dart';

class SupportRepositoryImpl implements SupportRepository {
  final SupabaseSupportDatasource _remoteDataSource;

  const SupportRepositoryImpl(this._remoteDataSource);

  @override
  Future<SupportWorkspace> getWorkspace() async {
    final categories = await _remoteDataSource.getCategories();
    final tickets = await _remoteDataSource.getMyTickets();
    
    return SupportWorkspace(
      categories: categories,
      tickets: tickets,
    );
  }

  @override
  Future<List<SupportTicket>> getMyTickets() {
    return _remoteDataSource.getMyTickets();
  }

  @override
  Future<SupportTicket> createTicket({
    required String category,
    required String title,
    required String description,
    required String priority,
    String? relatedBookingId,
    String? relatedTripId,
  }) {
    return _remoteDataSource.createTicket(
      category: category,
      title: title,
      description: description,
      priority: priority,
      relatedBookingId: relatedBookingId,
      relatedTripId: relatedTripId,
    );
  }

  @override
  Future<SupportTicket> getTicketDetails(String ticketId) {
    return _remoteDataSource.getTicketDetails(ticketId);
  }

  @override
  Future<List<SupportMessage>> getTicketMessages(String ticketId) {
    return _remoteDataSource.getTicketMessages(ticketId);
  }

  @override
  Future<List<SupportTimelineEvent>> getTicketTimeline(String ticketId) {
    return _remoteDataSource.getTicketTimeline(ticketId);
  }

  @override
  Future<SupportMessage> sendTicketMessage({
    required String ticketId,
    required String message,
  }) {
    return _remoteDataSource.sendTicketMessage(
      ticketId: ticketId,
      message: message,
    );
  }

  @override
  Future<SupportAttachment> uploadAttachment({
    required String ticketId,
    String? messageId,
    required File file,
  }) {
    return _remoteDataSource.uploadAttachment(
      ticketId: ticketId,
      messageId: messageId,
      file: file,
    );
  }

  @override
  Future<SupportRefundRequest> createRefundRequest({
    required String reason,
    String? description,
    required double amount,
    String? bookingId,
    String? tripId,
    File? evidenceFile,
  }) {
    return _remoteDataSource.createRefundRequest(
      reason: reason,
      description: description,
      amount: amount,
      bookingId: bookingId,
      tripId: tripId,
      evidenceFile: evidenceFile,
    );
  }

  @override
  Stream<List<SupportMessage>> subscribeToMessages(String ticketId) {
    return _remoteDataSource.subscribeToMessages(ticketId);
  }

  @override
  Stream<SupportTicket> subscribeToTicketUpdates(String ticketId) {
    return _remoteDataSource.subscribeToTicketUpdates(ticketId);
  }
}
