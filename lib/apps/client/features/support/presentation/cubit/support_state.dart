import '../../domain/entities/support_ticket.dart';

sealed class SupportState {
  const SupportState();
}

class SupportLoading extends SupportState {
  const SupportLoading();
}

class SupportLoaded extends SupportState {
  const SupportLoaded({
    required this.categories,
    required this.tickets,
    this.activeTicketId,
  });

  final List<String> categories;
  final List<SupportTicket> tickets;
  final String? activeTicketId;

  SupportTicket? get activeTicket {
    if (activeTicketId == null) return null;
    return tickets.cast<SupportTicket?>().firstWhere(
      (ticket) => ticket?.id == activeTicketId,
      orElse: () => null,
    );
  }

  SupportLoaded copyWith({
    List<SupportTicket>? tickets,
    String? activeTicketId,
  }) {
    return SupportLoaded(
      categories: categories,
      tickets: tickets ?? this.tickets,
      activeTicketId: activeTicketId ?? this.activeTicketId,
    );
  }
}

class SupportError extends SupportState {
  const SupportError(this.message);

  final String message;
}
