import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/support/domain/usecases/create_support_ticket_usecase.dart';
import 'package:bmt_app/apps/client/features/support/domain/usecases/get_my_support_tickets_usecase.dart';
import 'package:bmt_app/apps/client/features/support/domain/usecases/get_ticket_details_usecase.dart';
import 'package:bmt_app/apps/client/features/support/presentation/cubit/support_cubit.dart';
import 'package:bmt_app/apps/client/features/support/presentation/cubit/support_state.dart';

import 'support_test_doubles.dart';

SupportCubit _cubit(FakeSupportRepository repository) => SupportCubit(
  getMySupportTickets: GetMySupportTicketsUseCase(repository),
  createSupportTicket: CreateSupportTicketUseCase(repository),
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
