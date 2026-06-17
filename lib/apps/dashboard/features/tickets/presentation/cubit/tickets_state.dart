import '../../domain/entities/complaint.dart';

sealed class TicketsState {
  const TicketsState();
}

class TicketsLoading extends TicketsState {
  const TicketsLoading();
}

class TicketsError extends TicketsState {
  final String message;
  const TicketsError(this.message);
}

class TicketsLoaded extends TicketsState {
  final List<SupportTicket> tickets;
  final String? selectedTicketId;
  final TicketStatus? filterStatus;
  final TicketPriority? filterPriority;
  final String searchQuery;
  final bool actionLoading;
  final String? actionMessage;
  final List<SupportAttachment>? selectedTicketAttachments;
  final List<Map<String, dynamic>> agents;

  const TicketsLoaded({
    required this.tickets,
    this.selectedTicketId,
    this.filterStatus,
    this.filterPriority,
    this.searchQuery = '',
    this.actionLoading = false,
    this.actionMessage,
    this.selectedTicketAttachments,
    this.agents = const [],
  });

  SupportTicket? get selectedTicket {
    if (selectedTicketId == null || tickets.isEmpty) return null;
    for (final t in tickets) {
      if (t.id == selectedTicketId) return t;
    }
    return tickets.first;
  }

  List<SupportTicket> get filteredTickets {
    final result = tickets.where((t) {
      if (filterStatus != null && t.status != filterStatus) return false;
      if (filterPriority != null && t.priority != filterPriority) return false;
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final matchesId = t.ticketNumber.toLowerCase().contains(query);
        final matchesClient = t.clientName.toLowerCase().contains(query);
        final matchesPhone = t.clientPhone.toLowerCase().contains(query);
        final matchesTitle = t.title.toLowerCase().contains(query);
        if (!matchesId && !matchesClient && !matchesPhone && !matchesTitle) {
          return false;
        }
      }
      return true;
    }).toList();

    // breached first, then near-breach, then by remaining SLA time
    result.sort((a, b) {
      if (a.slaBreached != b.slaBreached) return a.slaBreached ? -1 : 1;
      if (a.isSlaNearBreach != b.isSlaNearBreach) return a.isSlaNearBreach ? -1 : 1;
      if (a.slaDueAt != null && b.slaDueAt != null) {
        return a.slaDueAt!.compareTo(b.slaDueAt!);
      }
      return 0;
    });

    return result;
  }

  // Summary Metrics
  int get newCount {
    return tickets.where((t) => t.status == TicketStatus.submitted).length;
  }

  int get underReviewCount {
    return tickets.where((t) => t.status == TicketStatus.underReview).length;
  }

  int get resolvedCount {
    return tickets.where((t) => t.status == TicketStatus.resolved).length;
  }

  int get delayedCount {
    final limit = DateTime.now().subtract(const Duration(hours: 24));
    return tickets.where((t) {
      final isUnresolved = t.status != TicketStatus.resolved && t.status != TicketStatus.closed;
      final isDelayed = t.createdAt.isBefore(limit);
      return isUnresolved && isDelayed;
    }).length;
  }

  TicketsLoaded copyWith({
    List<SupportTicket>? tickets,
    String? selectedTicketId,
    TicketStatus? filterStatus,
    TicketPriority? filterPriority,
    String? searchQuery,
    bool? actionLoading,
    String? actionMessage,
    List<SupportAttachment>? selectedTicketAttachments,
    List<Map<String, dynamic>>? agents,
    bool clearFilterStatus = false,
    bool clearFilterPriority = false,
  }) {
    return TicketsLoaded(
      tickets: tickets ?? this.tickets,
      selectedTicketId: selectedTicketId ?? this.selectedTicketId,
      filterStatus: clearFilterStatus ? null : (filterStatus ?? this.filterStatus),
      filterPriority: clearFilterPriority ? null : (filterPriority ?? this.filterPriority),
      searchQuery: searchQuery ?? this.searchQuery,
      actionLoading: actionLoading ?? this.actionLoading,
      actionMessage: actionMessage,
      selectedTicketAttachments: selectedTicketAttachments ?? this.selectedTicketAttachments,
      agents: agents ?? this.agents,
    );
  }
}
