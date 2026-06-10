import '../../domain/entities/complaint.dart';
import '../../domain/repositories/tickets_repository.dart';
import '../datasources/tickets_datasource.dart';

class TicketsRepositoryImpl implements TicketsRepository {
  final TicketsDatasource _datasource;

  const TicketsRepositoryImpl(this._datasource);

  @override
  Future<List<Complaint>> getComplaints() async {
    try {
      return await _datasource.getComplaints();
    } catch (_) {
      throw Exception('تعذر تحميل الشكاوى');
    }
  }

  @override
  Future<Complaint> assignComplaint(String id, String agentName) async {
    try {
      return await _datasource.assignComplaint(id, agentName);
    } catch (_) {
      throw Exception('تعذر تعيين الشكوى');
    }
  }

  @override
  Future<Complaint> respondToComplaint(
    String id, {
    required String senderName,
    required String senderType,
    required String content,
    required List<String> attachments,
  }) async {
    try {
      return await _datasource.respondToComplaint(
        id,
        senderName: senderName,
        senderType: senderType,
        content: content,
        attachments: attachments,
      );
    } catch (_) {
      throw Exception('تعذر إرسال الرد');
    }
  }

  @override
  Future<Complaint> updateComplaintStatus(String id, ComplaintStatus status) async {
    try {
      return await _datasource.updateComplaintStatus(id, status);
    } catch (_) {
      throw Exception('تعذر تحديث حالة الشكوى');
    }
  }

  @override
  Future<Complaint> escalateComplaint(String id) async {
    try {
      return await _datasource.escalateComplaint(id);
    } catch (_) {
      throw Exception('تعذر تصعيد الشكوى');
    }
  }

  @override
  Future<Complaint> closeComplaint(String id) async {
    try {
      return await _datasource.closeComplaint(id);
    } catch (_) {
      throw Exception('تعذر إغلاق الشكوى');
    }
  }
}
