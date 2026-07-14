import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/support/domain/usecases/create_support_ticket_usecase.dart';
import 'package:bmt_app/apps/client/features/support/domain/usecases/get_my_support_tickets_usecase.dart';
import 'package:bmt_app/apps/client/features/support/domain/usecases/get_ticket_details_usecase.dart';
import 'package:bmt_app/apps/client/features/support/presentation/cubit/support_cubit.dart';
import 'package:bmt_app/apps/client/features/support/presentation/widgets/create_ticket_form.dart';

import 'support_test_doubles.dart';

Future<FakeSupportRepository> _pumpForm(WidgetTester tester) async {
  final repository = FakeSupportRepository();

  // The form is a lazy ListView — on the default 800x600 test surface the
  // submit button below the fold would never be built.
  tester.view.physicalSize = const Size(1000, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<SupportCubit>(
        create: (_) => SupportCubit(
          getMySupportTickets: GetMySupportTicketsUseCase(repository),
          createSupportTicket: CreateSupportTicketUseCase(repository),
          getTicketDetails: GetTicketDetailsUseCase(repository),
          supportRepository: repository,
        ),
        child: const Scaffold(body: CreateTicketForm(isSubmitting: false)),
      ),
    ),
  );

  return repository;
}

void main() {
  group('CreateTicketForm', () {
    testWidgets('asks for the topic and never for a priority', (tester) async {
      await _pumpForm(tester);

      expect(find.text('What is this about?'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);

      expect(find.textContaining('Priority'), findsNothing);
      for (final level in ['LOW', 'MEDIUM', 'HIGH']) {
        expect(find.text(level), findsNothing);
      }
    });

    testWidgets('submits the picked topic with the typed ticket', (
      tester,
    ) async {
      final repository = await _pumpForm(tester);

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lost Item').last);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).first,
        'Left my bag on the bus',
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        'A black backpack, left on seat 12 this morning.',
      );

      await tester.tap(find.text('Submit ticket'));
      await tester.pump();

      expect(repository.lastCreateArgs?['category'], 'Lost Item');
      expect(repository.lastCreateArgs?['title'], 'Left my bag on the bus');
    });

    testWidgets('blocks an empty submission', (tester) async {
      final repository = await _pumpForm(tester);

      await tester.tap(find.text('Submit ticket'));
      await tester.pump();

      expect(find.text('Subject is required'), findsOneWidget);
      expect(find.text('Details are required'), findsOneWidget);
      expect(repository.lastCreateArgs, isNull);
    });
  });
}
