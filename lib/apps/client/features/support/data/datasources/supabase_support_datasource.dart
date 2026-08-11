import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/related_booking_option_model.dart';
import '../models/support_office_option_model.dart';
import '../models/support_ticket_model.dart';
import '../models/support_attachment_model.dart';

class SupabaseSupportDatasource {
  final SupabaseClient _supabase;

  const SupabaseSupportDatasource(this._supabase);

  String get _currentUserId {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return user.id;
  }

  Future<List<SupportTicketModel>> getMyTickets() async {
    final response = await _supabase
        .from('support_tickets')
        .select()
        .eq('client_id', _currentUserId)
        .order('created_at', ascending: false);

    return response.map((e) => SupportTicketModel.fromJson(e)).toList();
  }

  /// Clients no longer choose a priority — triage is the support team's job,
  /// so every client-filed ticket lands as `medium` and the dashboard raises
  /// it from there.
  static const String _defaultPriority = 'medium';

  Future<SupportTicketModel> createTicket({
    required String category,
    required String title,
    required String description,
    String? officeId,
    String? relatedBookingId,
    String? relatedTripId,
  }) async {
    final ticketNumber =
        '#TK-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    final insertData = {
      'client_id': _currentUserId,
      'ticket_number': ticketNumber,
      'category': category,
      'title': title,
      'description': description,
      'priority': _defaultPriority,
      'status': 'submitted',
      'office_id': officeId,
      'related_booking_id': relatedBookingId,
      'related_trip_id': relatedTripId,
    };

    final response = await _supabase
        .from('support_tickets')
        .insert(insertData)
        .select()
        .single();

    return SupportTicketModel.fromJson(response);
  }

  /// The client's most recent bookings, for the optional "related booking"
  /// picker on the create-ticket form. RLS already restricts the table to the
  /// caller's own rows; the explicit filter just keeps the query honest. The
  /// list is deliberately short — a complaint is about a recent trip, not
  /// booking history.
  Future<List<RelatedBookingOptionModel>> getRelatedBookingOptions() async {
    final response = await _supabase
        .from('operation_bookings')
        .select('id, trip_id, route, trip_date, seat')
        .eq('client_id', _currentUserId)
        .order('created_at', ascending: false)
        .limit(10);

    return response
        .map((e) => RelatedBookingOptionModel.fromJson(e))
        .toList();
  }

  /// The offices a client can direct a complaint to, for the create-ticket
  /// form's office picker. `public_offices` is the same sanitised marketplace
  /// surface the client already browses — it lists only active, listed offices,
  /// which is exactly the set the server accepts as a routing target.
  Future<List<SupportOfficeOptionModel>> getOfficeOptions() async {
    final response = await _supabase
        .from('public_offices')
        .select('id, name')
        .order('name', ascending: true);

    return response
        .map((e) => SupportOfficeOptionModel.fromJson(e))
        .toList();
  }

  Future<SupportTicketModel> getTicketDetails(String ticketId) async {
    final response = await _supabase
        .from('support_tickets')
        .select()
        .eq('id', ticketId)
        .eq('client_id', _currentUserId)
        .single();

    return SupportTicketModel.fromJson(response);
  }

  Future<List<SupportAttachmentModel>> getTicketAttachments(
    String ticketId,
  ) async {
    final response = await _supabase
        .from('support_attachments')
        .select()
        .eq('ticket_id', ticketId)
        .order('created_at', ascending: true);

    return response.map((e) => SupportAttachmentModel.fromJson(e)).toList();
  }

  Future<SupportAttachmentModel> uploadAttachment({
    required String ticketId,
    required File file,
  }) async {
    final fileName = '${const Uuid().v4()}_${file.path.split('/').last}';
    final filePath = 'tickets/$ticketId/$fileName';

    await _supabase.storage.from('support-attachments').upload(filePath, file);

    final fileUrl = _supabase.storage
        .from('support-attachments')
        .getPublicUrl(filePath);

    final insertData = {
      'ticket_id': ticketId,
      'file_url': fileUrl,
      'file_name': file.path.split('/').last,
      'file_type': file.path.split('.').last,
      'file_size': await file.length(),
    };

    final response = await _supabase
        .from('support_attachments')
        .insert(insertData)
        .select()
        .single();

    return SupportAttachmentModel.fromJson(response);
  }
}
