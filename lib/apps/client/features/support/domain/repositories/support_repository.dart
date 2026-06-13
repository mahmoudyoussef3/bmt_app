import '../entities/support_data.dart';
import '../entities/support_ticket.dart';

abstract class SupportRepository {
  Future<SupportData> getSupportData();
  Future<SupportTicket> createTicket(Map<String, dynamic> data);
  Future<SupportTicket> addMessage(String ticketId, Map<String, dynamic> message);
}
