import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

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
import 'package:bmt_app/apps/dashboard/features/tickets/presentation/widgets/tickets_board.dart';

/// The support queue, at the UI.
///
/// Before this pass the module rendered a raw Material `DataTable` with every
/// filtered ticket in one unpaginated column, a header that scrolled away, no
/// sort, and English status text on an Arabic-only console. The status and
/// priority filters existed in the cubit but no control on screen called them.

SupportTicket _ticket({
  required String number,
  String client = 'عميل',
  String title = 'شكوى',
  String category = 'تأخير',
  TicketPriority priority = TicketPriority.medium,
  TicketStatus status = TicketStatus.submitted,
  DateTime? createdAt,
  DateTime? slaDueAt,
  bool slaBreached = false,
  String? agent,
}) {
  final created = createdAt ?? DateTime(2026, 8, 1);
  return SupportTicket(
    id: 'id-$number',
    ticketNumber: number,
    clientId: 'c-$number',
    clientName: client,
    clientPhone: '01000000000',
    category: category,
    title: title,
    description: 'وصف',
    priority: priority,
    status: status,
    assignedAgentName: agent,
    createdAt: created,
    updatedAt: created,
    slaDueAt: slaDueAt,
    slaBreached: slaBreached,
  );
}

class _UnusedRepository implements TicketsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('the queue tests never hit the repository');
}

TicketsCubit _cubit() {
  final repository = _UnusedRepository();
  return TicketsCubit(
    getTickets: GetTicketsUseCase(repository),
    updateTicketStatus: UpdateTicketStatusUseCase(repository),
    saveInternalNote: SaveInternalNoteUseCase(repository),
    markCustomerContacted: MarkCustomerContactedUseCase(repository),
    closeTicket: CloseTicketUseCase(repository),
    getTicketAttachments: GetTicketAttachmentsUseCase(repository),
    assignAgent: AssignAgentUseCase(repository),
    getAgents: GetAgentsUseCase(repository),
  );
}

void main() {
  late TicketsCubit cubit;

  setUp(() => cubit = _cubit());
  tearDown(() => cubit.close());

  Future<void> pump(
    WidgetTester tester,
    TicketsLoaded state, {
    Size size = const Size(1600, 1200),
    double textScale = 1.0,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // The real screen renders the cubit's own state; seeding it keeps actions
    // that read `state` (clearing the filters) honest.
    cubit.emit(state);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(textScale)),
                child: BlocProvider.value(
                  value: cubit,
                  // The board reads the cubit's state, not the seeded object:
                  // the ordering lives in TicketsLoaded now, so a header tap
                  // has to come back through an emission to be visible.
                  child: BlocBuilder<TicketsCubit, TicketsState>(
                    builder: (context, current) => SingleChildScrollView(
                      child: TicketsBoard(state: current as TicketsLoaded),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('the queue reads in Arabic', () {
    testWidgets('status and priority render Arabic, never the enum name', (
      tester,
    ) async {
      await pump(
        tester,
        TicketsLoaded(
          tickets: [
            _ticket(
              number: 'T-1',
              status: TicketStatus.underReview,
              priority: TicketPriority.urgent,
            ),
          ],
          agents: const [],
        ),
      );

      expect(find.text('قيد المراجعة'), findsOneWidget);
      expect(find.text('عاجلة'), findsOneWidget);
      expect(find.text('Under Review'), findsNothing);
      expect(find.text('Urgent'), findsNothing);
    });

    testWidgets('a breached SLA says so in Arabic', (tester) async {
      await pump(
        tester,
        TicketsLoaded(
          tickets: [
            _ticket(
              number: 'T-1',
              slaDueAt: DateTime(2026, 8, 1),
              slaBreached: true,
            ),
          ],
          agents: const [],
        ),
      );

      expect(find.text('تجاوزت المهلة'), findsOneWidget);
      expect(find.text('BREACHED'), findsNothing);
    });

    testWidgets('the created date is zero-padded', (tester) async {
      await pump(
        tester,
        TicketsLoaded(
          tickets: [_ticket(number: 'T-1', createdAt: DateTime(2026, 8, 5))],
          agents: const [],
        ),
      );

      expect(find.text('2026/08/05'), findsOneWidget);
    });
  });

  group('the queue is paginated', () {
    testWidgets('a long queue renders one page, not every row', (tester) async {
      await pump(
        tester,
        TicketsLoaded(
          tickets: [
            for (var i = 0; i < 40; i++)
              _ticket(number: 'T-${i.toString().padLeft(2, '0')}'),
          ],
          agents: const [],
        ),
      );

      // 12 to a page: the 13th ticket is not built at all.
      expect(find.text('T-00'), findsOneWidget);
      expect(find.text('T-11'), findsOneWidget);
      expect(find.text('T-12'), findsNothing);
    });
  });

  group('the queue sorts', () {
    testWidgets('it opens on the SLA clock, soonest first', (tester) async {
      final now = DateTime(2026, 8, 10);
      await pump(
        tester,
        TicketsLoaded(
          tickets: [
            _ticket(
              number: 'T-LATE',
              slaDueAt: now.add(const Duration(days: 5)),
            ),
            _ticket(
              number: 'T-SOON',
              slaDueAt: now.add(const Duration(days: 1)),
            ),
            _ticket(number: 'T-NONE'),
          ],
          agents: const [],
        ),
      );

      final rows = tester
          .widgetList<Text>(find.textContaining('T-'))
          .map((t) => t.data)
          .toList();
      expect(rows.first, 'T-SOON');
      // A ticket with no clock is never what an SLA sort is looking for.
      expect(rows.last, 'T-NONE');
    });

    testWidgets('tapping a sortable header reorders the queue', (tester) async {
      await pump(
        tester,
        TicketsLoaded(
          tickets: [
            _ticket(number: 'T-B', client: 'باسم'),
            _ticket(number: 'T-A', client: 'أحمد'),
          ],
          agents: const [],
        ),
      );

      await tester.tap(find.text('رقم التذكرة'));
      await tester.pump();

      final rows = tester
          .widgetList<Text>(find.textContaining('T-'))
          .map((t) => t.data)
          .toList();
      expect(rows.first, 'T-A');
    });
  });

  group('empty states say why', () {
    testWidgets('an empty queue explains where tickets come from', (
      tester,
    ) async {
      await pump(tester, const TicketsLoaded(tickets: [], agents: []));

      expect(find.text('لا توجد شكاوى'), findsOneWidget);
      expect(find.textContaining('تطبيق الركاب'), findsOneWidget);
      // Nothing to clear, so no clear action is offered.
      expect(find.text('مسح الفلاتر'), findsNothing);
    });

    testWidgets('a filtered-to-nothing queue offers to clear the filters', (
      tester,
    ) async {
      await pump(
        tester,
        TicketsLoaded(
          tickets: [_ticket(number: 'T-1', client: 'أحمد')],
          agents: const [],
          searchQuery: 'لا يوجد عميل بهذا الاسم',
        ),
      );

      expect(find.text('لا توجد تذاكر مطابقة'), findsOneWidget);

      await tester.tap(find.text('مسح الفلاتر'));
      await tester.pump();

      final state = cubit.state as TicketsLoaded;
      expect(state.searchQuery, isEmpty);
      expect(state.filterStatus, isNull);
      expect(state.filterPriority, isNull);
    });
  });

  group('the filters reach the query', () {
    test('status and priority narrow the queue', () {
      cubit.emit(
        TicketsLoaded(
          tickets: [
            _ticket(number: 'T-1', status: TicketStatus.submitted),
            _ticket(number: 'T-2', status: TicketStatus.closed),
            _ticket(
              number: 'T-3',
              status: TicketStatus.submitted,
              priority: TicketPriority.urgent,
            ),
          ],
          agents: const [],
        ),
      );

      cubit.setFilterStatus(TicketStatus.submitted);
      expect((cubit.state as TicketsLoaded).filteredTickets.length, 2);

      cubit.setFilterPriority(TicketPriority.urgent);
      final narrowed = (cubit.state as TicketsLoaded).filteredTickets;
      expect(narrowed.single.ticketNumber, 'T-3');

      cubit.clearFilters();
      expect((cubit.state as TicketsLoaded).filteredTickets.length, 3);
    });
  });

  group('the queue survives its window', () {
    for (final size in const [Size(1600, 1200), Size(1100, 900)]) {
      for (final scale in const [1.0, 1.3]) {
        testWidgets('no overflow at ${size.width}px / ${scale}x text', (
          tester,
        ) async {
          await pump(
            tester,
            TicketsLoaded(
              tickets: [
                _ticket(
                  number: 'TCK-2026-0001',
                  client: 'محمد عبد الرحمن السيد',
                  title: 'تأخر الرحلة أكثر من ساعة دون إشعار مسبق للركاب',
                  category: 'تأخير الرحلات',
                  agent: 'خدمة العملاء',
                  slaDueAt: DateTime(2030),
                ),
              ],
              agents: const [],
            ),
            size: size,
            textScale: scale,
          );

          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
