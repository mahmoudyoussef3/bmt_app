import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
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

  Future<List<String>> getCategories() async {
    return [
      'Booking Issue',
      'Payment Issue',
      'Trip Delay',
      'Driver or Vehicle Issue',
      'Subscription Issue',
      'Lost Item',
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
      'status': 'submitted',
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

  Future<SupportTicketModel> getTicketDetails(String ticketId) async {
    final response = await _supabase
        .from('support_tickets')
        .select()
        .eq('id', ticketId)
        .eq('client_id', _currentUserId)
        .single();

    return SupportTicketModel.fromJson(response);
  }

  Future<List<SupportAttachmentModel>> getTicketAttachments(String ticketId) async {
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

    final fileUrl = _supabase.storage.from('support-attachments').getPublicUrl(filePath);

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
