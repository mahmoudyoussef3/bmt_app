import '../../domain/entities/complaint.dart';

abstract class TicketsDatasource {
  Future<List<Complaint>> getComplaints();
  Future<Complaint> assignComplaint(String id, String agentName);
  Future<Complaint> respondToComplaint(
    String id, {
    required String senderName,
    required String senderType,
    required String content,
    required List<String> attachments,
  });
  Future<Complaint> updateComplaintStatus(String id, ComplaintStatus status);
  Future<Complaint> escalateComplaint(String id);
  Future<Complaint> closeComplaint(String id);
}
