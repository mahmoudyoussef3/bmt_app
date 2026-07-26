import 'dart:io';

import 'package:bmt_app/apps/client/features/support/domain/entities/related_booking_option.dart';
import 'package:bmt_app/apps/client/features/support/domain/entities/support_attachment.dart';
import 'package:bmt_app/apps/client/features/support/domain/entities/support_office_option.dart';
import 'package:bmt_app/apps/client/features/support/domain/entities/support_ticket.dart';
import 'package:bmt_app/apps/client/features/support/domain/repositories/support_repository.dart';

SupportTicket supportTicketFixture({
  String id = 'ticket-1',
  String category = 'Payment Issue',
  String title = 'Charged twice for one booking',
}) {
  final now = DateTime(2026, 7, 14);
  return SupportTicket(
    id: id,
    ticketNumber: '#TK-0001',
    category: category,
    title: title,
    description: 'The same booking was charged to my card two times.',
    priority: TicketPriority.medium,
    status: TicketStatus.submitted,
    createdAt: now,
    updatedAt: now,
  );
}

/// Hand-rolled test double — the project pulls in no mocking package, so the
/// support tests drive the cubit through a repository they control directly.
class FakeSupportRepository implements SupportRepository {
  FakeSupportRepository({
    List<SupportTicket>? tickets,
    this.relatedBookingOptions = const [],
    this.officeOptions = const [],
    this.throwOnLoad,
  }) : tickets = tickets ?? [];

  List<SupportTicket> tickets;

  /// Bookings offered to the create form's optional "related booking" picker.
  final List<RelatedBookingOption> relatedBookingOptions;

  /// Offices offered to the create form's required office picker.
  final List<SupportOfficeOption> officeOptions;

  /// When set, [getMyTickets] throws it instead of returning [tickets].
  final Object? throwOnLoad;

  /// Arguments the cubit last passed to [createTicket], for asserting that the
  /// client-facing form sends exactly what it collected — and nothing else.
  Map<String, String?>? lastCreateArgs;

  int uploadCount = 0;

  @override
  Future<List<SupportTicket>> getMyTickets() async {
    final failure = throwOnLoad;
    if (failure != null) throw failure;
    return tickets;
  }

  @override
  Future<SupportTicket> createTicket({
    required String category,
    required String title,
    required String description,
    String? officeId,
    String? relatedBookingId,
    String? relatedTripId,
  }) async {
    lastCreateArgs = {
      'category': category,
      'title': title,
      'description': description,
      'officeId': officeId,
      'relatedBookingId': relatedBookingId,
      'relatedTripId': relatedTripId,
    };

    final ticket = supportTicketFixture(
      id: 'ticket-new',
      category: category,
      title: title,
    );
    tickets = [ticket, ...tickets];
    return ticket;
  }

  @override
  Future<SupportTicket> getTicketDetails(String ticketId) async {
    return tickets.firstWhere((ticket) => ticket.id == ticketId);
  }

  @override
  Future<List<RelatedBookingOption>> getRelatedBookingOptions() async {
    return relatedBookingOptions;
  }

  @override
  Future<List<SupportOfficeOption>> getOfficeOptions() async {
    return officeOptions;
  }

  @override
  Future<List<SupportAttachment>> getTicketAttachments(String ticketId) async {
    return const [];
  }

  @override
  Future<SupportAttachment> uploadAttachment({
    required String ticketId,
    required File file,
  }) async {
    uploadCount++;
    return SupportAttachment(
      id: 'attachment-1',
      ticketId: ticketId,
      fileUrl: 'https://example.test/${file.path}',
      fileName: file.path,
      fileType: 'png',
      createdAt: DateTime(2026, 7, 14),
    );
  }
}
