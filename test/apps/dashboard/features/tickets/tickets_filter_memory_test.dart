import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_filter_memory.dart';
import 'package:bmt_app/apps/dashboard/features/tickets/domain/entities/complaint.dart';
import 'package:bmt_app/apps/dashboard/features/tickets/domain/repositories/tickets_repository.dart';
import 'package:bmt_app/apps/dashboard/features/tickets/domain/usecases/assign_agent_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/tickets/domain/usecases/close_ticket_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/tickets/domain/usecases/get_ticket_attachments_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/tickets/domain/usecases/get_tickets_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/tickets/domain/usecases/mark_customer_contacted_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/tickets/domain/usecases/save_internal_note_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/tickets/domain/usecases/update_ticket_status_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/tickets/presentation/cubit/tickets_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/tickets/presentation/cubit/tickets_state.dart';

SupportTicket _ticket(
  String id, {
  TicketStatus status = TicketStatus.submitted,
  TicketPriority priority = TicketPriority.medium,
  String title = 'شكوى',
}) {
  return SupportTicket(
    id: id,
    ticketNumber: 'T-$id',
    clientId: 'c-$id',
    clientName: 'عميل $id',
    clientPhone: '0100',
    category: 'حجز',
    title: title,
    description: 'وصف',
    priority: priority,
    status: status,
    createdAt: DateTime(2026, 8, 10),
    updatedAt: DateTime(2026, 8, 10),
  );
}

class _FakeRepo implements TicketsRepository {
  _FakeRepo(this.seed);

  final List<SupportTicket> seed;

  @override
  Future<List<SupportTicket>> getTickets() async => seed;

  @override
  Future<List<Map<String, dynamic>>> getAgents() async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

TicketsCubit _cubit(_FakeRepo repo) => TicketsCubit(
  getTickets: GetTicketsUseCase(repo),
  updateTicketStatus: UpdateTicketStatusUseCase(repo),
  saveInternalNote: SaveInternalNoteUseCase(repo),
  markCustomerContacted: MarkCustomerContactedUseCase(repo),
  closeTicket: CloseTicketUseCase(repo),
  getTicketAttachments: GetTicketAttachmentsUseCase(repo),
  assignAgent: AssignAgentUseCase(repo),
  getAgents: GetAgentsUseCase(repo),
);

void main() {
  setUp(DashboardFilterMemory.instance.clear);
  tearDown(DashboardFilterMemory.instance.clear);

  group('the support queue remembers its triage across navigation', () {
    // An agent narrows to "العاجلة المفتوحة", opens a ticket to read it, and
    // comes back. The shell built a new cubit in between — that is what a
    // second `_cubit(repo)` over the same repo stands for.
    test('status and priority are restored on return', () async {
      final repo = _FakeRepo([_ticket('1'), _ticket('2')]);
      final before = _cubit(repo);
      await before.load();
      before.setFilterStatus(TicketStatus.underReview);
      before.setFilterPriority(TicketPriority.urgent);
      await before.close();

      final after = _cubit(repo);
      await after.load();

      final state = after.state as TicketsLoaded;
      expect(state.filterStatus, TicketStatus.underReview);
      expect(state.filterPriority, TicketPriority.urgent);
      await after.close();
    });

    test('the search text is restored too', () async {
      final repo = _FakeRepo([_ticket('1')]);
      final before = _cubit(repo);
      await before.load();
      before.setSearchQuery('تأخير');
      await before.close();

      final after = _cubit(repo);
      await after.load();

      expect((after.state as TicketsLoaded).searchQuery, 'تأخير');
      await after.close();
    });

    test('a restored filter actually narrows the queue', () async {
      // Restoring the field but not applying it would be worse than
      // forgetting: the chip would claim a filter the list is not honouring.
      final repo = _FakeRepo([
        _ticket('1', priority: TicketPriority.urgent),
        _ticket('2'),
        _ticket('3'),
      ]);
      final before = _cubit(repo);
      await before.load();
      before.setFilterPriority(TicketPriority.urgent);
      await before.close();

      final after = _cubit(repo);
      await after.load();

      expect((after.state as TicketsLoaded).filteredTickets.length, 1);
      await after.close();
    });

    test('clearing filters survives navigation as well', () async {
      final repo = _FakeRepo([_ticket('1')]);
      final before = _cubit(repo);
      await before.load();
      before.setFilterPriority(TicketPriority.urgent);
      before.clearFilters();
      await before.close();

      final after = _cubit(repo);
      await after.load();

      final state = after.state as TicketsLoaded;
      expect(state.filterPriority, isNull);
      expect(state.filterStatus, isNull);
      expect(state.searchQuery, isEmpty);
      await after.close();
    });

    test('sign-out leaves the next operator an unfiltered queue', () async {
      final repo = _FakeRepo([_ticket('1')]);
      final before = _cubit(repo);
      await before.load();
      before.setFilterStatus(TicketStatus.underReview);
      await before.close();

      DashboardFilterMemory.instance.clear();

      final after = _cubit(repo);
      await after.load();

      expect((after.state as TicketsLoaded).filterStatus, isNull);
      await after.close();
    });

    test('bookings and tickets do not share a memory slot', () async {
      final repo = _FakeRepo([_ticket('1')]);
      final cubit = _cubit(repo);
      await cubit.load();
      cubit.setFilterStatus(TicketStatus.underReview);

      expect(DashboardFilterMemory.instance.debugSnapshot.keys, [
        DashboardFilterIds.tickets,
      ]);
      await cubit.close();
    });
  });
}
