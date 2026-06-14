import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/support_ticket_model.dart';
import '../models/support_message_model.dart';
import '../models/support_attachment_model.dart';
import '../models/support_timeline_event_model.dart';
import '../models/support_refund_request_model.dart';

class SupabaseSupportDatasource {
  final SupabaseClient _supabase;

  const SupabaseSupportDatasource(this._supabase);

  String get _currentUserId {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return user.id;
  }

  Future<List<String>> getCategories() async {
    return [
      'Booking Issue',
      'Driver Issue',
      'Vehicle Issue',
      'Route Issue',
      'Technical Issue',
      'Refund Request',
      'Other',
    ];
  }

  Future<List<SupportTicketModel>> getMyTickets() async {
    final response = await _supabase
        .from('support_tickets')
        .select()
        .eq('client_id', _currentUserId)
        .order('created_at', ascending: false);

    return response.map((e) => SupportTicketModel.fromJson(e)).toList();
  }

  Future<SupportTicketModel> createTicket({
    required String category,
    required String title,
    required String description,
    required String priority,
    String? relatedBookingId,
    String? relatedTripId,
  }) async {
    final ticketNumber = '#TK-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    final insertData = {
      'client_id': _currentUserId,
      'ticket_number': ticketNumber,
      'category': category,
      'title': title,
      'description': description,
      'priority': priority.toLowerCase(),
      'status': 'open',
      'related_booking_id': relatedBookingId,
      'related_trip_id': relatedTripId,
    };

    final response = await _supabase
        .from('support_tickets')
        .insert(insertData)
        .select()
        .single();

    // Create an initial timeline event
    await _supabase.from('support_timeline_events').insert({
      'ticket_id': response['id'],
      'title': 'Ticket Created',
      'description': 'Your support ticket has been received.',
      'event_type': 'created',
      'done': true,
    });

    return SupportTicketModel.fromJson(response);
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

  Future<List<SupportMessageModel>> getTicketMessages(String ticketId) async {
    final response = await _supabase
        .from('support_messages')
        .select('*, attachments:support_attachments(*)')
        .eq('ticket_id', ticketId)
        .order('created_at', ascending: true);

    return response.map((e) => SupportMessageModel.fromJson(e)).toList();
  }

  Future<List<SupportTimelineEventModel>> getTicketTimeline(String ticketId) async {
    final response = await _supabase
        .from('support_timeline_events')
        .select()
        .eq('ticket_id', ticketId)
        .order('created_at', ascending: true);

    return response.map((e) => SupportTimelineEventModel.fromJson(e)).toList();
  }

  Future<SupportMessageModel> sendTicketMessage({
    required String ticketId,
    required String message,
  }) async {
    // Get client profile for name gracefully
    String senderName = 'Client';
    try {
      final clientResponse = await _supabase
          .from('clients')
          .select('full_name')
          .eq('id', _currentUserId)
          .maybeSingle();
      if (clientResponse != null && clientResponse['full_name'] != null) {
        senderName = clientResponse['full_name'];
      }
    } catch (_) {
      // Ignore if clients table/row is missing
    }

    final insertData = {
      'ticket_id': ticketId,
      'sender_type': 'client',
      'sender_id': _currentUserId,
      'sender_name': senderName,
      'message': message,
    };

    final response = await _supabase
        .from('support_messages')
        .insert(insertData)
        .select()
        .single();

    return SupportMessageModel.fromJson(response);
  }

  Future<SupportAttachmentModel> uploadAttachment({
    required String ticketId,
    String? messageId,
    required File file,
  }) async {
    final fileName = '${const Uuid().v4()}_${file.path.split('/').last}';
    final filePath = 'tickets/$ticketId/$fileName';

    await _supabase.storage.from('support-attachments').upload(filePath, file);

    final fileUrl = _supabase.storage.from('support-attachments').getPublicUrl(filePath);

    final insertData = {
      'ticket_id': ticketId,
      'message_id': messageId,
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

  Future<SupportRefundRequestModel> createRefundRequest({
    required String reason,
    String? description,
    required double amount,
    String? bookingId,
    String? tripId,
    File? evidenceFile,
  }) async {
    String? evidenceUrl;
    
    if (evidenceFile != null) {
      final fileName = '${const Uuid().v4()}_${evidenceFile.path.split('/').last}';
      final filePath = 'refunds/$_currentUserId/$fileName';
      await _supabase.storage.from('support-attachments').upload(filePath, evidenceFile);
      evidenceUrl = _supabase.storage.from('support-attachments').getPublicUrl(filePath);
    }

    final insertData = {
      'client_id': _currentUserId,
      'booking_id': bookingId,
      'trip_id': tripId,
      'reason': reason,
      'description': description,
      'amount': amount,
      'evidence_url': evidenceUrl,
    };

    final response = await _supabase
        .from('refund_requests')
        .insert(insertData)
        .select()
        .single();

    return SupportRefundRequestModel.fromJson(response);
  }

  Stream<List<SupportMessageModel>> subscribeToMessages(String ticketId) {
    return _supabase
        .from('support_messages')
        .stream(primaryKey: ['id'])
        .eq('ticket_id', ticketId)
        .order('created_at')
        .map((events) => events.map((e) => SupportMessageModel.fromJson(e)).toList());
  }

  Stream<SupportTicketModel> subscribeToTicketUpdates(String ticketId) {
    return _supabase
        .from('support_tickets')
        .stream(primaryKey: ['id'])
        .eq('id', ticketId)
        .map((events) => SupportTicketModel.fromJson(events.first));
  }
}
