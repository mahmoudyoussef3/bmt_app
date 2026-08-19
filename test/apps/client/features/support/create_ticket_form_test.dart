import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/support/domain/entities/related_booking_option.dart';
import 'package:bmt_app/apps/client/features/support/domain/entities/support_office_option.dart';
import 'package:bmt_app/apps/client/features/support/domain/usecases/create_support_ticket_usecase.dart';
import 'package:bmt_app/apps/client/features/support/domain/usecases/get_my_support_tickets_usecase.dart';
import 'package:bmt_app/apps/client/features/support/domain/usecases/get_related_booking_options_usecase.dart';
import 'package:bmt_app/apps/client/features/support/domain/usecases/get_support_office_options_usecase.dart';
import 'package:bmt_app/apps/client/features/support/domain/usecases/get_ticket_details_usecase.dart';
import 'package:bmt_app/apps/client/features/support/presentation/cubit/support_cubit.dart';
import 'package:bmt_app/apps/client/features/support/presentation/cubit/support_state.dart';
import 'package:bmt_app/apps/client/features/support/presentation/widgets/create_ticket_form.dart';

import 'support_test_doubles.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

Future<FakeSupportRepository> _pumpForm(
  WidgetTester tester, {
  List<SupportOfficeOption> officeOptions = const [
    SupportOfficeOption(id: 'office-1', name: 'Cairo'),
  ],
  List<RelatedBookingOption> bookingOptions = const [],
}) async {
  // A single office is auto-selected, so the required office picker never blocks
  // these tests from exercising the rest of the form.
  final repository = FakeSupportRepository(
    officeOptions: officeOptions,
    relatedBookingOptions: bookingOptions,
  );

  // The form is a lazy ListView — on the default 800x600 test surface the
  // submit button below the fold would never be built.
  tester.view.physicalSize = const Size(1000, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider<SupportCubit>(
        create: (_) => SupportCubit(
          getMySupportTickets: GetMySupportTicketsUseCase(repository),
          createSupportTicket: CreateSupportTicketUseCase(repository),
          getRelatedBookingOptions: GetRelatedBookingOptionsUseCase(repository),
          getOfficeOptions: GetSupportOfficeOptionsUseCase(repository),
          getTicketDetails: GetTicketDetailsUseCase(repository),
          supportRepository: repository,
        ),
        // Mirrors the real screen's BlocConsumer: the form is rebuilt when the
        // cubit reports its picker options finished loading.
        child: Scaffold(
          body: BlocBuilder<SupportCubit, SupportState>(
            builder: (context, state) =>
                CreateTicketForm(isSubmitting: state is SupportActionLoading),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

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

    testWidgets('files against the office that operated the linked booking', (
      tester,
    ) async {
      // Two offices, so nothing is auto-selected: the client's own pick would
      // otherwise decide the destination.
      final repository = await _pumpForm(
        tester,
        officeOptions: const [
          SupportOfficeOption(id: 'office-1', name: 'Cairo'),
          SupportOfficeOption(id: 'office-2', name: 'Luxor'),
        ],
        bookingOptions: const [
          RelatedBookingOption(
            bookingId: 'booking-1',
            tripId: 'trip-1',
            route: 'Cairo to Luxor',
            officeId: 'office-2',
          ),
        ],
      );

      await tester.tap(
        find.byType(DropdownButtonFormField<RelatedBookingOption?>),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cairo to Luxor').last);
      await tester.pumpAndSettle();

      // The picker now shows the operating office and refuses a different one.
      final officeField = tester
          .widget<DropdownButtonFormField<SupportOfficeOption>>(
            find.byType(DropdownButtonFormField<SupportOfficeOption>),
          );
      expect(officeField.onChanged, isNull);

      await tester.enterText(
        find.byType(TextFormField).first,
        'Bus never arrived',
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        'Waited an hour at the station and nobody showed up.',
      );

      await tester.tap(find.text('Submit ticket'));
      await tester.pump();

      expect(repository.lastCreateArgs?['officeId'], 'office-2');
      expect(repository.lastCreateArgs?['relatedBookingId'], 'booking-1');
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
