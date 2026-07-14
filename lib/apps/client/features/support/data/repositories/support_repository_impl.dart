import 'dart:io';
import '../../domain/entities/support_ticket.dart';
import '../../domain/entities/support_attachment.dart';
import '../../domain/repositories/support_repository.dart';
import '../datasources/supabase_support_datasource.dart';

class SupportRepositoryImpl implements SupportRepository {
  final SupabaseSupportDatasource _remoteDataSource;

  const SupportRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<SupportTicket>> getMyTickets() {
    return _remoteDataSource.getMyTickets();
  }

  @override
  Future<SupportTicket> createTicket({
    required String category,
    required String title,
    required String description,
    String? relatedBookingId,
    String? relatedTripId,
  }) {
    return _remoteDataSource.createTicket(
      category: category,
      title: title,
      description: description,
      relatedBookingId: relatedBookingId,
      relatedTripId: relatedTripId,
    );
  }

  @override
  Future<SupportTicket> getTicketDetails(String ticketId) {
    return _remoteDataSource.getTicketDetails(ticketId);
  }

  @override
  Future<List<SupportAttachment>> getTicketAttachments(String ticketId) {
    return _remoteDataSource.getTicketAttachments(ticketId);
  }

  @override
  Future<SupportAttachment> uploadAttachment({
    required String ticketId,
    required File file,
  }) {
    return _remoteDataSource.uploadAttachment(ticketId: ticketId, file: file);
  }
}
