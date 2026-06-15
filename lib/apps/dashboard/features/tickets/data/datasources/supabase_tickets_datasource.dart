import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/complaint.dart';
import '../models/complaint_model.dart';
import 'tickets_datasource.dart';

class SupabaseTicketsDatasource implements TicketsDatasource {
  final SupabaseClient _client;
  static const String _table = 'support_tickets';

  SupabaseTicketsDatasource(this._client);

  @override
  Future<List<Complaint>> getComplaints() async {
    final response = await _client.from(_table).select('''
      *,
      client:clients(id, full_name, phone),
      messages:support_messages(
        id, sender_name, sender_type, message, created_at, 
        attachments:support_attachments(file_url)
      ),
      timeline:support_timeline_events(
        id, event_type, title, description, created_at
      )
    ''').order('created_at', ascending: false);

    return response.map((json) {
      return _mapToComplaintModel(json);
    }).toList();
  }

  @override
  Future<Complaint> assignComplaint(String id, String agentName) async {
    // Update the ticket
    await _client.from(_table).update({
      'assigned_to': agentName,
    }).eq('id', id);

    // Add an event
    await _client.from('support_timeline_events').insert({
      'ticket_id': id,
      'title': 'تم تعيين الشكوى إلى المسؤول: $agentName',
      'event_type': 'assigned',
      'done': true,
    });

    return _fetchSingleComplaint(id);
  }

  @override
  Future<Complaint> respondToComplaint(
    String id, {
    required String senderName,
    required String senderType,
    required String content,
    required List<String> attachments,
  }) async {
    // 1. Insert message
    await _client.from('support_messages').insert({
      'ticket_id': id,
      'sender_type': senderType,
      'sender_name': senderName,
      'message': content,
    });

    // 2. Add an event
    await _client.from('support_timeline_events').insert({
      'ticket_id': id,
      'title': 'تم إرسال رد من قبل $senderName',
      'event_type': 'message',
      'done': true,
    });

    // 3. Update status if needed
    final ticket = await _client.from(_table).select('status').eq('id', id).single();
    if (senderType == 'agent' && ticket['status'] == 'open') {
      await _client.from(_table).update({'status': 'waitingForClient'}).eq('id', id);
    }

    return _fetchSingleComplaint(id);
  }

  @override
  Future<Complaint> updateComplaintStatus(String id, ComplaintStatus status) async {
    await _client.from(_table).update({
      'status': status.name,
    }).eq('id', id);

    await _client.from('support_timeline_events').insert({
      'ticket_id': id,
      'title': 'تم تغيير حالة الشكوى إلى: ${status.label}',
      'event_type': 'status_change',
      'done': true,
    });

    return _fetchSingleComplaint(id);
  }

  @override
  Future<Complaint> escalateComplaint(String id) async {
    await _client.from(_table).update({
      'priority': ComplaintPriority.critical.name,
    }).eq('id', id);

    await _client.from('support_timeline_events').insert({
      'ticket_id': id,
      'title': 'تم تصعيد الشكوى وتغيير الأولوية إلى حرجة',
      'event_type': 'escalation',
      'done': true,
    });

    return _fetchSingleComplaint(id);
  }

  @override
  Future<Complaint> closeComplaint(String id) async {
    await _client.from(_table).update({
      'status': ComplaintStatus.closed.name,
    }).eq('id', id);

    await _client.from('support_timeline_events').insert({
      'ticket_id': id,
      'title': 'تم إغلاق الشكوى نهائياً',
      'event_type': 'closed',
      'done': true,
    });

    return _fetchSingleComplaint(id);
  }

  @override
  Future<void> deleteComplaint(String id) async {
    // Delete events, messages, attachments first if there are foreign keys without cascade delete
    // Typically Supabase handles cascading deletes if configured, but doing explicitly ensures cleanup
    await _client.from('support_timeline_events').delete().eq('ticket_id', id);
    await _client.from('support_messages').delete().eq('ticket_id', id);
    await _client.from(_table).delete().eq('id', id);
  }

  // --- Helper Methods ---

  Future<Complaint> _fetchSingleComplaint(String id) async {
    final response = await _client.from(_table).select('''
      *,
      client:clients(id, full_name, phone),
      messages:support_messages(
        id, sender_name, sender_type, message, created_at, 
        attachments:support_attachments(file_url)
      ),
      timeline:support_timeline_events(
        id, event_type, title, description, created_at
      )
    ''').eq('id', id).single();

    return _mapToComplaintModel(response);
  }

  ComplaintModel _mapToComplaintModel(Map<String, dynamic> data) {
    final client = data['client'] as Map<String, dynamic>?;
    final clientName = client?['full_name']?.toString() ?? 'عميل غير معروف';
    final clientPhone = client?['phone']?.toString() ?? 'رقم غير متوفر';

    // Map category to enum
    final rawCategory = data['category']?.toString() ?? '';
    String mappedCategory = 'other';
    if (rawCategory.contains('Booking') || rawCategory.contains('Route')) mappedCategory = 'tripDelay';
    if (rawCategory.contains('Driver')) mappedCategory = 'driverBehavior';
    if (rawCategory.contains('Vehicle')) mappedCategory = 'vehicleCleanliness';
    if (rawCategory.contains('Technical')) mappedCategory = 'appIssue';
    if (rawCategory.contains('Refund') || rawCategory.contains('Payment')) mappedCategory = 'paymentIssue';

    // Map status
    final rawStatus = data['status']?.toString() ?? 'newlyCreated';
    String mappedStatus = rawStatus == 'open' ? 'newlyCreated' : rawStatus;
    if (data['assigned_to'] != null && rawStatus == 'open') mappedStatus = 'inProgress';

    // Map priority
    final rawPriority = data['priority']?.toString() ?? 'low';

    final messages = (data['messages'] as List<dynamic>? ?? []).map((m) {
      final msg = m as Map<String, dynamic>;
      final attachments = (msg['attachments'] as List<dynamic>? ?? [])
          .map((a) => (a as Map<String, dynamic>)['file_url']?.toString() ?? '')
          .toList();
      return {
        'id': msg['id'],
        'sender_name': msg['sender_name'] ?? 'Unknown',
        'sender_type': msg['sender_type'] ?? 'client',
        'content': msg['message'] ?? '',
        'timestamp': msg['created_at'],
        'attachments': attachments,
      };
    }).toList();

    final timeline = (data['timeline'] as List<dynamic>? ?? []).map((t) {
      final evt = t as Map<String, dynamic>;
      return {
        'id': evt['id'],
        'action': evt['title'] ?? evt['description'] ?? 'System Event',
        'timestamp': evt['created_at'],
        'actor': 'النظام',
      };
    }).toList();

    final payload = {
      'id': data['id'],
      'client_name': clientName,
      'client_phone': clientPhone,
      'category': mappedCategory,
      'trip_code': data['related_trip_id'] ?? data['related_booking_id'] ?? '',
      'created_at': data['created_at'],
      'assigned_to': data['assigned_to'],
      'status': mappedStatus,
      'priority': rawPriority,
      'description': data['description'] ?? '',
      'conversation': messages,
      'attachments': [],
      'history': timeline,
    };

    return ComplaintModel.fromJson(payload);
  }
}
