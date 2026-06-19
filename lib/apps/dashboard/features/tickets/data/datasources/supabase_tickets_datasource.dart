import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/complaint.dart';
import '../models/complaint_model.dart';

class SupabaseTicketsDatasource {
  final SupabaseClient _client;
  static const String _table = 'support_tickets';

  SupabaseTicketsDatasource(this._client);

  Future<List<SupportTicketModel>> getTickets() async {
    final response = await _client
        .from(_table)
        .select('''
      *,
      clients:client_id(id, full_name, phone)
    ''')
        .order('created_at', ascending: false);

    return response.map((json) {
      return SupportTicketModel.fromJson(json);
    }).toList();
  }

  Future<SupportTicketModel> updateTicketStatus(
    String id,
    TicketStatus status,
  ) async {
    final response = await _client
        .from(_table)
        .update({'status': status.name})
        .eq('id', id)
        .select('''
      *,
      clients:client_id(id, full_name, phone)
    ''')
        .single();

    return SupportTicketModel.fromJson(response);
  }

  Future<SupportTicketModel> saveInternalNote(String id, String note) async {
    final response = await _client
        .from(_table)
        .update({'internal_note': note})
        .eq('id', id)
        .select('''
      *,
      clients:client_id(id, full_name, phone)
    ''')
        .single();

    return SupportTicketModel.fromJson(response);
  }

  Future<SupportTicketModel> markCustomerContacted(String id) async {
    final response = await _client
        .from(_table)
        .update({
          'customer_contacted_at': DateTime.now().toUtc().toIso8601String(),
          'status': 'contacted',
        })
        .eq('id', id)
        .select('''
      *,
      clients:client_id(id, full_name, phone)
    ''')
        .single();

    return SupportTicketModel.fromJson(response);
  }

  Future<SupportTicketModel> closeTicket(String id) async {
    final response = await _client
        .from(_table)
        .update({
          'status': 'closed',
          'closed_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id)
        .select('''
      *,
      clients:client_id(id, full_name, phone)
    ''')
        .single();

    return SupportTicketModel.fromJson(response);
  }

  Future<List<SupportAttachmentModel>> getTicketAttachments(
    String ticketId,
  ) async {
    final response = await _client
        .from('support_attachments')
        .select()
        .eq('ticket_id', ticketId)
        .order('created_at', ascending: true);

    return response
        .map((json) => SupportAttachmentModel.fromJson(json))
        .toList();
  }

  Future<SupportTicketModel> assignAgent(
    String ticketId,
    String agentId,
    String agentName,
  ) async {
    final response = await _client
        .from(_table)
        .update({
          'assigned_agent_id': agentId,
          'assigned_agent_name': agentName,
        })
        .eq('id', ticketId)
        .select('''
      *,
      clients:client_id(id, full_name, phone)
    ''')
        .single();
    return SupportTicketModel.fromJson(response);
  }

  Future<List<Map<String, dynamic>>> getAgents() async {
    final rows = await _client
        .from('user_roles')
        .select('user_id, role')
        .not('role', 'eq', 'client')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }
}
