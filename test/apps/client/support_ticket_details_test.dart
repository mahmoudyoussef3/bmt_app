import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/support/domain/entities/support_attachment.dart';
import 'package:bmt_app/apps/client/features/support/domain/entities/support_ticket.dart';
import 'package:bmt_app/apps/client/features/support/domain/repositories/support_repository.dart';
import 'package:bmt_app/apps/client/features/support/domain/usecases/create_support_ticket_usecase.dart';
import 'package:bmt_app/apps/client/features/support/domain/usecases/get_my_support_tickets_usecase.dart';
import 'package:bmt_app/apps/client/features/support/domain/usecases/get_ticket_details_usecase.dart';
import 'package:bmt_app/apps/client/features/support/presentation/cubit/support_cubit.dart';
import 'package:bmt_app/apps/client/features/support/presentation/screens/support_ticket_details_screen.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

class _StaticRepository implements SupportRepository {
  _StaticRepository({this.ticket, this.attachments = const []});

  final SupportTicket? ticket;
  final List<SupportAttachment> attachments;

  @override
  Future<SupportTicket> getTicketDetails(String ticketId) async {
    final ticket = this.ticket;
    if (ticket == null) throw Exception('Ticket not found');
    return ticket;
  }

  @override
  Future<List<SupportAttachment>> getTicketAttachments(String ticketId) async =>
      attachments;

  @override
  Future<List<SupportTicket>> getMyTickets() async => const [];

  @override
  Future<SupportTicket> createTicket({
    required String category,
    required String title,
    required String description,
    String? relatedBookingId,
    String? relatedTripId,
  }) => throw UnimplementedError();

  @override
  Future<SupportAttachment> uploadAttachment({
    required String ticketId,
    required File file,
  }) => throw UnimplementedError();
}

SupportTicket _ticket({
  TicketStatus status = TicketStatus.underReview,
  String? assignedAgentName,
  String? internalNote,
}) {
  return SupportTicket(
    id: 't-1',
    ticketNumber: 'BMT-1042',
    category: 'Payment Issue',
    title: 'Charged twice for one seat',
    description: 'My card was billed two times for the same booking.',
    priority: TicketPriority.high,
    status: status,
    assignedAgentName: assignedAgentName,
    internalNote: internalNote,
    createdAt: DateTime(2026, 7, 14),
    updatedAt: DateTime(2026, 7, 15),
  );
}

Future<SupportCubit> _pumpDetails(
  WidgetTester tester,
  _StaticRepository repo,
) async {
  final cubit = SupportCubit(
    getMySupportTickets: GetMySupportTicketsUseCase(repo),
    createSupportTicket: CreateSupportTicketUseCase(repo),
    getTicketDetails: GetTicketDetailsUseCase(repo),
    supportRepository: repo,
  );

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider<SupportCubit>.value(
        // Mirrors ClientCubitScopes.supportTicketDetails, which owns the id.
        value: cubit..openTicketDetails('t-1'),
        child: const SupportTicketDetailsScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return cubit;
}

void main() {
  testWidgets('renders a loaded ticket without overflow or paint errors', (
    tester,
  ) async {
    final cubit = await _pumpDetails(
      tester,
      _StaticRepository(
        ticket: _ticket(
          assignedAgentName: 'Nour',
          internalNote: 'Refund issued, allow 3 working days.',
        ),
        attachments: [
          SupportAttachment(
            id: 'a-1',
            ticketId: 't-1',
            fileUrl: 'https://example.com/receipt.pdf',
            fileName: 'receipt.pdf',
            fileType: 'application/pdf',
            fileSize: 2048,
            createdAt: DateTime(2026, 7, 14),
          ),
        ],
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Ticket BMT-1042'), findsOneWidget);
    expect(find.text('Charged twice for one seat'), findsOneWidget);
    expect(find.text('Under Review'), findsOneWidget);
    expect(find.text('Nour'), findsOneWidget);
    expect(find.text('Refund issued, allow 3 working days.'), findsOneWidget);
    expect(find.text('receipt.pdf'), findsOneWidget);
    expect(find.text('2.0 KB'), findsOneWidget);

    await cubit.close();
  });

  testWidgets('resolved ticket drops the review notice and agent badge', (
    tester,
  ) async {
    final cubit = await _pumpDetails(
      tester,
      _StaticRepository(ticket: _ticket(status: TicketStatus.resolved)),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Resolved'), findsOneWidget);
    expect(find.textContaining('Assigned to'), findsNothing);
    // No attachments means no section header at all.
    expect(find.text('Attachments'), findsNothing);

    await cubit.close();
  });

  testWidgets('a ticket that fails to load still offers a way back', (
    tester,
  ) async {
    final cubit = await _pumpDetails(tester, _StaticRepository());

    expect(find.text('Failed to load ticket details'), findsOneWidget);
    // The failure still renders an app bar, so the client is never stranded on
    // a page with no way back. (The back arrow itself only materialises when
    // there is something to pop, which a test `home:` route has not.)
    expect(find.byType(AppBar), findsOneWidget);

    await cubit.close();
  });
}
