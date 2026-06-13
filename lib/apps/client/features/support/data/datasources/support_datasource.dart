import '../models/support_ticket_model.dart';

abstract class SupportDatasource {
  Future<List<String>> getCategories();
  Future<List<SupportTicketModel>> getTickets();
  Future<SupportTicketModel> createTicket(Map<String, dynamic> data);
  Future<SupportTicketModel> addMessage(String ticketId, Map<String, dynamic> message);
}
