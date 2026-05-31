import 'dart:async';
import '../../domain/models/support_ticket.dart';
import '../../domain/repositories/support_ticket_repository.dart';

class MockSupportTicketRepository implements SupportTicketRepository {
  final List<SupportTicket> _store = List.generate(
    12,
    (i) => SupportTicket(
      id: 'TKT-${i + 1}',
      customerId: i % 2 == 0 ? 'CUST-${i + 1}' : 'DRIVER-${i + 1}',
      subject: 'Issue with booking ${i + 1}',
      description: 'Customer reports a problem with the booking.',
      priority: i % 4 == 0
          ? TicketPriority.critical
          : (i % 3 == 0 ? TicketPriority.high : TicketPriority.medium),
      status: i % 5 == 0
          ? TicketStatus.escalated
          : (i % 4 == 0 ? TicketStatus.inProgress : TicketStatus.open),
      internalNotes: i % 6 == 0
          ? [InternalNote(agentId: 'AGENT-1', note: 'Initial triage done')]
          : [],
    ),
  );
  @override
  Future<void> addInternalNote(
    String ticketId,
    String agentId,
    String note,
  ) async {
    final idx = _store.indexWhere((t) => t.id == ticketId);
    if (idx >= 0) {
      final t = _store[idx];
      final updated = SupportTicket(
        id: t.id,
        customerId: t.customerId,
        subject: t.subject,
        description: t.description,
        status: t.status,
        priority: t.priority,
        createdAt: t.createdAt,
        updatedAt: DateTime.now(),
        attachments: t.attachments,
        assignedAgentId: t.assignedAgentId,
        internalNotes: List.from(t.internalNotes)
          ..add(InternalNote(agentId: agentId, note: note)),
      );
      _store[idx] = updated;
    }
    await Future.delayed(Duration(milliseconds: 100));
  }

  @override
  Future<SupportTicket> createTicket(SupportTicket ticket) async {
    _store.insert(0, ticket);
    return ticket;
  }

  @override
  Future<SupportTicket> getTicket(String id) async {
    final t = _store.firstWhere((t) => t.id == id);
    return t;
  }

  @override
  Future<List<SupportTicket>> fetchTickets({
    TicketStatus? status,
    TicketPriority? priority,
    int limit = 50,
    int offset = 0,
  }) async {
    List<SupportTicket> res = _store;
    if (status != null) res = res.where((r) => r.status == status).toList();
    if (priority != null)
      res = res.where((r) => r.priority == priority).toList();
    await Future.delayed(Duration(milliseconds: 200));
    return res.skip(offset).take(limit).toList();
  }

  @override
  Future<void> updateTicket(SupportTicket ticket) async {
    final idx = _store.indexWhere((t) => t.id == ticket.id);
    if (idx >= 0) _store[idx] = ticket;
    await Future.delayed(Duration(milliseconds: 100));
  }
}
