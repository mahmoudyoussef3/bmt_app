import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/complaint.dart';
import '../models/complaint_model.dart';
import 'tickets_datasource.dart';

class SupabaseTicketsDatasource implements TicketsDatasource {
  final SupabaseClient _client;
  static const String _table = 'operation_complaints';

  SupabaseTicketsDatasource(this._client);

  @override
  Future<List<Complaint>> getComplaints() async {
    final response = await _client.from(_table).select().order('created_at', ascending: false);
    return response.map((json) => ComplaintModel.fromJson(json)).toList();
  }

  @override
  Future<Complaint> assignComplaint(String id, String agentName) async {
    final complaintData = await _client.from(_table).select().eq('id', id).single();
    final complaint = ComplaintModel.fromJson(complaintData);

    final updatedHistory = [
      ...complaint.history,
      ComplaintLogModel(
        id: 'log-${DateTime.now().millisecondsSinceEpoch}',
        action: 'تم تعيين الشكوى إلى المسؤول: $agentName',
        timestamp: DateTime.now(),
        actor: 'النظام',
      ),
    ];

    final response = await _client.from(_table).update({
      'assigned_to': agentName,
      'history': updatedHistory.map((e) => ComplaintLogModel.fromEntity(e).toJson()).toList(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id).select().single();

    return ComplaintModel.fromJson(response);
  }

  @override
  Future<Complaint> respondToComplaint(
    String id, {
    required String senderName,
    required String senderType,
    required String content,
    required List<String> attachments,
  }) async {
    final complaintData = await _client.from(_table).select().eq('id', id).single();
    final complaint = ComplaintModel.fromJson(complaintData);

    final newMessage = ComplaintMessageModel(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
      senderName: senderName,
      senderType: senderType,
      content: content,
      timestamp: DateTime.now(),
      attachments: attachments,
    );

    var newStatus = complaint.status;
    if (senderType == 'agent' &&
        (complaint.status == ComplaintStatus.newlyCreated ||
            complaint.status == ComplaintStatus.inProgress)) {
      newStatus = ComplaintStatus.waitingForClient;
    }

    final updatedConversation = [...complaint.conversation, newMessage];
    final updatedHistory = [
      ...complaint.history,
      ComplaintLogModel(
        id: 'log-${DateTime.now().millisecondsSinceEpoch}',
        action: 'تم إرسال رد من قبل $senderName',
        timestamp: DateTime.now(),
        actor: senderName,
      ),
    ];

    final response = await _client.from(_table).update({
      'status': newStatus.name,
      'conversation': updatedConversation.map((e) => ComplaintMessageModel.fromEntity(e).toJson()).toList(),
      'history': updatedHistory.map((e) => ComplaintLogModel.fromEntity(e).toJson()).toList(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id).select().single();

    return ComplaintModel.fromJson(response);
  }

  @override
  Future<Complaint> updateComplaintStatus(String id, ComplaintStatus status) async {
    final complaintData = await _client.from(_table).select().eq('id', id).single();
    final complaint = ComplaintModel.fromJson(complaintData);

    final updatedHistory = [
      ...complaint.history,
      ComplaintLogModel(
        id: 'log-${DateTime.now().millisecondsSinceEpoch}',
        action: 'تم تغيير حالة الشكوى إلى: ${status.label}',
        timestamp: DateTime.now(),
        actor: 'المسؤول',
      ),
    ];

    final response = await _client.from(_table).update({
      'status': status.name,
      'history': updatedHistory.map((e) => ComplaintLogModel.fromEntity(e).toJson()).toList(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id).select().single();

    return ComplaintModel.fromJson(response);
  }

  @override
  Future<Complaint> escalateComplaint(String id) async {
    final complaintData = await _client.from(_table).select().eq('id', id).single();
    final complaint = ComplaintModel.fromJson(complaintData);

    final updatedHistory = [
      ...complaint.history,
      ComplaintLogModel(
        id: 'log-${DateTime.now().millisecondsSinceEpoch}',
        action: 'تم تصعيد الشكوى وتغيير الأولوية إلى حرجة',
        timestamp: DateTime.now(),
        actor: 'المسؤول',
      ),
    ];

    final response = await _client.from(_table).update({
      'priority': ComplaintPriority.critical.name,
      'history': updatedHistory.map((e) => ComplaintLogModel.fromEntity(e).toJson()).toList(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id).select().single();

    return ComplaintModel.fromJson(response);
  }

  @override
  Future<Complaint> closeComplaint(String id) async {
    final complaintData = await _client.from(_table).select().eq('id', id).single();
    final complaint = ComplaintModel.fromJson(complaintData);

    final updatedHistory = [
      ...complaint.history,
      ComplaintLogModel(
        id: 'log-${DateTime.now().millisecondsSinceEpoch}',
        action: 'تم إغلاق الشكوى نهائياً',
        timestamp: DateTime.now(),
        actor: 'المسؤول',
      ),
    ];

    final response = await _client.from(_table).update({
      'status': ComplaintStatus.closed.name,
      'history': updatedHistory.map((e) => ComplaintLogModel.fromEntity(e).toJson()).toList(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id).select().single();

    return ComplaintModel.fromJson(response);
  }
}
