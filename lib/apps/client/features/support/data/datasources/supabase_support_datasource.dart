import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/support_ticket.dart';
import '../models/support_ticket_model.dart';
import 'support_datasource.dart';

class SupabaseSupportDatasource implements SupportDatasource {
  final SupabaseClient _supabase;

  const SupabaseSupportDatasource(this._supabase);

  TicketStatus _mapStatus(String status) {
    switch (status.toLowerCase()) {
      case 'newlycreated':
      case 'open':
        return TicketStatus.open;
      case 'inprogress':
        return TicketStatus.inProgress;
      case 'resolved':
      case 'closed':
        return TicketStatus.resolved;
      default:
        return TicketStatus.open;
    }
  }

  SupportTicketModel _mapToModel(Map<String, dynamic> data) {
    final conversationList = data['conversation'] as List<dynamic>? ?? [];
    final conversation = conversationList.map((e) => Map<String, String>.from(e as Map)).toList();
    
    final attachmentsList = data['attachments'] as List<dynamic>? ?? [];
    final attachments = attachmentsList.map((e) => e.toString()).toList();

    return SupportTicketModel(
      id: data['id']?.toString() ?? '',
      category: data['category']?.toString() ?? 'Other',
      title: data['category']?.toString() ?? 'Support Request', // Usually we don't have title column in operation_complaints, so we fallback
      description: data['description']?.toString() ?? '',
      priority: data['priority']?.toString() ?? 'low',
      status: _mapStatus(data['status']?.toString() ?? 'open'),
      dateCreated: data['created_at'] != null ? data['created_at'].toString().split('T')[0] : 'Unknown',
      attachedImages: attachments,
      conversation: conversation,
    );
  }

  @override
  Future<List<String>> getCategories() async {
    return const [
      'Booking Issue',
      'Driver Issue',
      'Vehicle Issue',
      'Route Issue',
      'Technical Issue',
      'Refund Request',
      'Other',
    ];
  }

  @override
  Future<List<SupportTicketModel>> getTickets() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final response = await _supabase
        .from('operation_complaints')
        .select()
        .eq('client_id', user.id)
        .order('created_at', ascending: false);

    return response.map((e) => _mapToModel(e)).toList();
  }

  @override
  Future<SupportTicketModel> createTicket(Map<String, dynamic> data) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Get client details for the required columns
    final clientResponse = await _supabase
        .from('clients')
        .select()
        .eq('id', user.id)
        .single();
    
    final newId = '#TK-${Random().nextInt(9000) + 1000}';
    final initialMessage = {
      'sender': 'user',
      'text': data['description']?.toString() ?? '',
      'time': 'Just now',
    };

    final insertData = {
      'id': newId,
      'client_id': user.id,
      'client_name': clientResponse['full_name'] ?? 'Unknown User',
      'client_phone': clientResponse['phone'] ?? 'Unknown',
      'category': data['category'],
      'trip_code': 'N/A', // If not specified
      'status': 'open',
      'priority': data['priority']?.toString().toLowerCase() ?? 'low',
      'description': data['description'],
      'conversation': [initialMessage],
      'attachments': (data['imageAttached'] == true) ? ['uploaded_issue_photo.png'] : [],
    };

    final response = await _supabase
        .from('operation_complaints')
        .insert(insertData)
        .select()
        .single();

    return _mapToModel(response);
  }

  @override
  Future<SupportTicketModel> addMessage(String ticketId, Map<String, dynamic> message) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Fetch existing ticket to append to conversation
    final ticket = await _supabase
        .from('operation_complaints')
        .select()
        .eq('id', ticketId)
        .eq('client_id', user.id)
        .single();

    final List<dynamic> currentConv = ticket['conversation'] as List<dynamic>? ?? [];
    currentConv.add(message);

    final response = await _supabase
        .from('operation_complaints')
        .update({'conversation': currentConv})
        .eq('id', ticketId)
        .select()
        .single();

    return _mapToModel(response);
  }
}
