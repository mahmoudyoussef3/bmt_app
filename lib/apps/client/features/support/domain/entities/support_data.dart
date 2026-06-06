import 'support_ticket.dart';

class SupportData {
  const SupportData({required this.categories, required this.tickets});

  final List<String> categories;
  final List<SupportTicket> tickets;
}
