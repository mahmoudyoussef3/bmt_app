import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/support/data/datasources/mock_support_datasource.dart';
import 'package:bmt_app/apps/client/features/support/data/repositories/support_repository_impl.dart';
import 'package:bmt_app/apps/client/features/support/domain/entities/support_ticket.dart';
import 'package:bmt_app/apps/client/features/support/domain/usecases/add_support_message_usecase.dart';
import 'package:bmt_app/apps/client/features/support/domain/usecases/create_support_ticket_usecase.dart';
import 'package:bmt_app/apps/client/features/support/domain/usecases/get_support_data_usecase.dart';
import 'package:bmt_app/apps/client/features/support/presentation/cubit/support_cubit.dart';
import 'package:bmt_app/apps/client/features/support/presentation/cubit/support_state.dart';

void main() {
  group('Client support', () {
    late SupportRepositoryImpl repository;

    setUp(() {
      repository = const SupportRepositoryImpl(MockSupportDatasource());
    });

    test('returns support categories and user tickets', () async {
      final data = await GetSupportDataUseCase(repository)();

      expect(data.categories, contains('Refund Request'));
      expect(data.tickets, hasLength(2));
      expect(data.tickets.first.status, TicketStatus.inProgress);
    });

    test('creates deterministic support tickets when seeded', () {
      final createTicket = CreateSupportTicketUseCase(random: Random(42));

      final ticket = createTicket(
        category: 'Booking Issue',
        title: 'Missing booking',
        description: 'My ticket did not appear',
        priority: 'High',
        imageAttached: true,
      );

      expect(ticket.id, '#TK-6587');
      expect(ticket.status, TicketStatus.open);
      expect(ticket.attachedImages.single, 'uploaded_issue_photo.png');
      expect(ticket.conversation.single['text'], 'My ticket did not appear');
    });

    test('adds user and agent messages through cubit', () async {
      final cubit = SupportCubit(
        getSupportData: GetSupportDataUseCase(repository),
        createTicket: CreateSupportTicketUseCase(random: Random(42)),
        addMessage: const AddSupportMessageUseCase(),
      );

      await cubit.load();
      final loaded = cubit.state as SupportLoaded;
      cubit.openTicket(loaded.tickets.first);
      cubit.addUserMessage('Any update?');
      cubit.addAgentReply(loaded.tickets.first.id);

      final state = cubit.state as SupportLoaded;
      expect(state.activeTicket?.conversation.last['sender'], 'agent');
      expect(state.activeTicket?.conversation, hasLength(4));

      await cubit.close();
    });
  });
}
