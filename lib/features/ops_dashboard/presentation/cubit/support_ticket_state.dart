import '../../domain/models/support_ticket.dart';

abstract class SupportTicketState {}

class SupportTicketLoading extends SupportTicketState {}

class SupportTicketLoaded extends SupportTicketState {
  final List<SupportTicket> tickets;
  final TicketStatus? filterStatus;
  final String? searchQuery;

  SupportTicketLoaded(this.tickets, {this.filterStatus, this.searchQuery});
}

class SupportTicketError extends SupportTicketState {
  final String message;
  SupportTicketError(this.message);
}
