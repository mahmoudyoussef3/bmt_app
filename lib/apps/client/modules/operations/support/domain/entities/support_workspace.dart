import 'support_ticket.dart';

class SupportWorkspace {
  const SupportWorkspace({required this.categories, required this.tickets});

  final List<String> categories;
  final List<SupportTicket> tickets;
}
