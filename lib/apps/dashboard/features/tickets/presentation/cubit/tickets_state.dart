import '../../domain/entities/complaint.dart';
import '../models/ticket_sort.dart';
import 'package:bmt_app/apps/dashboard/core/query/dashboard_query_caps.dart';

/// How many tickets one page of the queue holds. The same number الاشتراكات and
/// العملاء page by, so the الدعم section does not read as a different console.
const int ticketsPageSize = 12;

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
  final String? filterCategory;
  final TicketAssignment filterAssignment;

  /// The «متأخرة» queue, which is not a status: a ticket is overdue when it is
  /// still open past the office's 24-hour promise, whatever status it carries.
  final bool overdueOnly;

  final String searchQuery;
  final TicketSort sort;
  final bool sortAscending;
  final bool actionLoading;
  final String? actionMessage;
  final List<SupportAttachment>? selectedTicketAttachments;
  final List<Map<String, dynamic>> agents;

  /// True when the query came back full at [DashboardQueryCaps.tickets], so
  /// this queue is the newest slice of the office's history rather than all of
  /// it. The screen says so rather than presenting a window as a total.
  bool get capReached => tickets.length >= DashboardQueryCaps.tickets;

  const TicketsLoaded({
    required this.tickets,
    this.selectedTicketId,
    this.filterStatus,
    this.filterPriority,
    this.filterCategory,
    this.filterAssignment = TicketAssignment.any,
    this.overdueOnly = false,
    this.searchQuery = '',
    this.sort = TicketSort.sla,
    this.sortAscending = true,
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

  /// Every category the office's own tickets actually carry, for the filter
  /// dropdown. Derived rather than declared: the category is free text on the
  /// passenger's side, so a hard-coded list would go stale silently.
  List<String> get categories {
    final seen = <String>{};
    for (final ticket in tickets) {
      final category = ticket.category.trim();
      if (category.isNotEmpty) seen.add(category);
    }
    final sorted = seen.toList()..sort();
    return sorted;
  }

  bool _isOverdue(SupportTicket ticket) {
    final limit = DateTime.now().subtract(const Duration(hours: 24));
    final isUnresolved =
        ticket.status != TicketStatus.resolved &&
        ticket.status != TicketStatus.closed;
    return isUnresolved && ticket.createdAt.isBefore(limit);
  }

  List<SupportTicket> get filteredTickets {
    final result = tickets.where((t) {
      if (filterStatus != null && t.status != filterStatus) return false;
      if (filterPriority != null && t.priority != filterPriority) return false;
      if (filterCategory != null && t.category != filterCategory) return false;
      if (overdueOnly && !_isOverdue(t)) return false;
      switch (filterAssignment) {
        case TicketAssignment.any:
          break;
        case TicketAssignment.unassigned:
          if (t.assignedAgentId != null || t.assignedAgentName != null) {
            return false;
          }
        case TicketAssignment.assigned:
          if (t.assignedAgentId == null && t.assignedAgentName == null) {
            return false;
          }
      }
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

    result.sort((a, b) {
      if (a.slaBreached != b.slaBreached) {
        return a.slaBreached ? -1 : 1;
      }
      if (a.isSlaNearBreach != b.isSlaNearBreach) {
        return a.isSlaNearBreach ? -1 : 1;
      }
      if (a.slaDueAt != null && b.slaDueAt != null) {
        return a.slaDueAt!.compareTo(b.slaDueAt!);
      }
      return 0;
    });

    return result;
  }

  /// [filteredTickets] in the order the agent asked for.
  ///
  /// A ticket with no SLA clock sorts last however the column is pointed — it
  /// is never the thing an agent sorting by المهلة is looking for.
  List<SupportTicket> get visibleTickets {
    final sorted = [...filteredTickets];

    int compare(SupportTicket a, SupportTicket b) => switch (sort) {
      TicketSort.ticketNumber => a.ticketNumber.compareTo(b.ticketNumber),
      TicketSort.client => a.clientName.compareTo(b.clientName),
      TicketSort.priority => a.priority.index.compareTo(b.priority.index),
      TicketSort.createdAt => a.createdAt.compareTo(b.createdAt),
      TicketSort.sla => switch ((a.slaDueAt, b.slaDueAt)) {
        (null, null) => 0,
        (null, _) => 1,
        (_, null) => -1,
        (final x?, final y?) => x.compareTo(y),
      },
    };

    sorted.sort((a, b) {
      if (sort == TicketSort.sla &&
          (a.slaDueAt == null || b.slaDueAt == null)) {
        return compare(a, b);
      }
      final result = compare(a, b);
      return sortAscending ? result : -result;
    });
    return sorted;
  }

  /// Drives the reset button's badge. The sort is not a filter — it changes the
  /// order, not the population — so it is not counted here.
  int get activeFilterCount => [
    searchQuery.trim().isNotEmpty,
    filterStatus != null,
    filterPriority != null,
    filterCategory != null,
    filterAssignment != TicketAssignment.any,
    overdueOnly,
  ].where((active) => active).length;

  bool get isFiltered => activeFilterCount > 0;

  int get newCount {
    return tickets.where((t) => t.status == TicketStatus.submitted).length;
  }

  int get underReviewCount {
    return tickets.where((t) => t.status == TicketStatus.underReview).length;
  }

  int get resolvedCount {
    return tickets.where((t) => t.status == TicketStatus.resolved).length;
  }

  int get delayedCount => tickets.where(_isOverdue).length;

  TicketsLoaded copyWith({
    List<SupportTicket>? tickets,
    String? selectedTicketId,
    TicketStatus? filterStatus,
    TicketPriority? filterPriority,
    String? filterCategory,
    TicketAssignment? filterAssignment,
    bool? overdueOnly,
    String? searchQuery,
    TicketSort? sort,
    bool? sortAscending,
    bool? actionLoading,
    String? actionMessage,
    List<SupportAttachment>? selectedTicketAttachments,
    List<Map<String, dynamic>>? agents,
    bool clearFilterStatus = false,
    bool clearFilterPriority = false,
    bool clearFilterCategory = false,
  }) {
    return TicketsLoaded(
      tickets: tickets ?? this.tickets,
      selectedTicketId: selectedTicketId ?? this.selectedTicketId,
      filterStatus: clearFilterStatus
          ? null
          : (filterStatus ?? this.filterStatus),
      filterPriority: clearFilterPriority
          ? null
          : (filterPriority ?? this.filterPriority),
      filterCategory: clearFilterCategory
          ? null
          : (filterCategory ?? this.filterCategory),
      filterAssignment: filterAssignment ?? this.filterAssignment,
      overdueOnly: overdueOnly ?? this.overdueOnly,
      searchQuery: searchQuery ?? this.searchQuery,
      sort: sort ?? this.sort,
      sortAscending: sortAscending ?? this.sortAscending,
      actionLoading: actionLoading ?? this.actionLoading,
      actionMessage: actionMessage,
      selectedTicketAttachments:
          selectedTicketAttachments ?? this.selectedTicketAttachments,
      agents: agents ?? this.agents,
    );
  }
}
