import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/support/domain/entities/related_booking_option.dart';
import 'package:bmt_app/apps/client/features/support/domain/usecases/create_support_ticket_usecase.dart';
import 'package:bmt_app/apps/client/features/support/domain/usecases/get_my_support_tickets_usecase.dart';
import 'package:bmt_app/apps/client/features/support/domain/usecases/get_related_booking_options_usecase.dart';
import 'package:bmt_app/apps/client/features/support/domain/usecases/get_support_office_options_usecase.dart';
import 'package:bmt_app/apps/client/features/support/domain/usecases/get_ticket_details_usecase.dart';
import 'package:bmt_app/apps/client/features/support/presentation/cubit/support_cubit.dart';
import 'package:bmt_app/apps/client/features/support/presentation/cubit/support_state.dart';

import 'support_test_doubles.dart';

SupportCubit _cubit(FakeSupportRepository repository) => SupportCubit(
  getMySupportTickets: GetMySupportTicketsUseCase(repository),
  createSupportTicket: CreateSupportTicketUseCase(repository),
  getRelatedBookingOptions: GetRelatedBookingOptionsUseCase(repository),
  getOfficeOptions: GetSupportOfficeOptionsUseCase(repository),
  getTicketDetails: GetTicketDetailsUseCase(repository),
  supportRepository: repository,
);

void main() {
  group('SupportCubit', () {
    test('loadTickets emits loading then the client\'s tickets', () async {
      final repository = FakeSupportRepository(
        tickets: [supportTicketFixture()],
      );
      final cubit = _cubit(repository);

      expectLater(
        cubit.stream,
        emitsInOrder([
          isA<SupportLoading>(),
          isA<SupportLoaded>().having(
            (state) => state.tickets.single.id,
            'ticket id',
            'ticket-1',
          ),
        ]),
      );

      await cubit.loadTickets();
      await cubit.close();
    });

    test('loadTickets surfaces a failure as an error state', () async {
      final repository = FakeSupportRepository(
        throwOnLoad: Exception('Network unreachable'),
      );
      final cubit = _cubit(repository);

      await cubit.loadTickets();

      expect(cubit.state, isA<SupportError>());
      expect(
        (cubit.state as SupportError).message,
        'Network unreachable',
        reason: 'the Exception: prefix should be stripped for the UI',
      );
      await cubit.close();
    });

    test('createTicket sends only what the client filled in', () async {
      final repository = FakeSupportRepository();
      final cubit = _cubit(repository);

      await cubit.createTicket(
        category: 'Lost Item',
        title: 'Left my bag on the bus',
        description: 'A black backpack, left on seat 12 this morning.',
      );

      expect(repository.lastCreateArgs, {
        'category': 'Lost Item',
        'title': 'Left my bag on the bus',
        'description': 'A black backpack, left on seat 12 this morning.',
        'officeId': null,
        'relatedBookingId': null,
        'relatedTripId': null,
      });
      expect(
        repository.uploadCount,
        0,
        reason: 'no attachment was provided, so nothing should be uploaded',
      );
      await cubit.close();
    });

    /// The office a ticket reaches is derived server-side from this linkage —
    /// so the one thing the cubit must guarantee is that the picked booking's
    /// ids arrive at the repository untouched.
    test('createTicket forwards the picked booking and trip ids', () async {
      final repository = FakeSupportRepository();
      final cubit = _cubit(repository);

      await cubit.createTicket(
        category: 'Trip Delay',
        title: 'Bus was late',
        description: 'The 07:00 trip left at 09:05 with no announcement.',
        relatedBookingId: 'booking-9',
        relatedTripId: 'trip-3',
      );

      expect(repository.lastCreateArgs?['relatedBookingId'], 'booking-9');
      expect(repository.lastCreateArgs?['relatedTripId'], 'trip-3');
      await cubit.close();
    });

    test('loadRelatedBookingOptions exposes bookings for the picker', () async {
      final repository = FakeSupportRepository(
        relatedBookingOptions: const [
          RelatedBookingOption(
            bookingId: 'booking-9',
            tripId: 'trip-3',
            route: 'Nasr City → Obour',
          ),
        ],
      );
      final cubit = _cubit(repository);

      expectLater(cubit.stream, emits(isA<SupportRelatedBookingsLoaded>()));

      await cubit.loadRelatedBookingOptions();

      expect(cubit.relatedBookingOptions.single.bookingId, 'booking-9');
      expect(cubit.relatedBookingOptions.single.tripId, 'trip-3');
      await cubit.close();
    });

    test('a client with no bookings gets no picker and no state churn', () async {
      final repository = FakeSupportRepository();
      final cubit = _cubit(repository);

      expectLater(cubit.stream, emitsDone);

      await cubit.loadRelatedBookingOptions();

      expect(cubit.relatedBookingOptions, isEmpty);
      await cubit.close();
    });

    /// The create screen's cubit is disposed the moment that screen pops, so
    /// createTicket must not queue a reload of its own — it would emit after
    /// close, and the list it refreshed is not the one the client is looking
    /// at anyway.
    test(
      'createTicket reports success without reloading its own list',
      () async {
        final repository = FakeSupportRepository();
        final cubit = _cubit(repository);

        expectLater(
          cubit.stream,
          emitsInOrder([
            isA<SupportActionLoading>(),
            isA<SupportSuccess>().having(
              (state) => state.ticket?.category,
              'created ticket category',
              'Trip Delay',
            ),
            emitsDone,
          ]),
        );

        await cubit.createTicket(
          category: 'Trip Delay',
          title: 'Bus was two hours late',
          description: 'The 07:00 trip left at 09:05 with no announcement.',
        );
        await cubit.close();
      },
    );
  });
}
