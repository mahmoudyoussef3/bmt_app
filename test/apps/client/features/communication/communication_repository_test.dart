import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/communication/data/datasources/mock_communication_datasource.dart';
import 'package:bmt_app/apps/client/features/communication/data/repositories/communication_repository_impl.dart';
import 'package:bmt_app/apps/client/features/communication/domain/entities/conversation.dart';
import 'package:bmt_app/apps/client/features/communication/domain/usecases/add_conversation_message_usecase.dart';
import 'package:bmt_app/apps/client/features/communication/domain/usecases/get_conversations_usecase.dart';
import 'package:bmt_app/apps/client/features/communication/presentation/cubit/communication_cubit.dart';
import 'package:bmt_app/apps/client/features/communication/presentation/cubit/communication_state.dart';

void main() {
  group('Client communication', () {
    late CommunicationRepositoryImpl repository;

    setUp(() {
      repository = const CommunicationRepositoryImpl(
        MockCommunicationDatasource(),
      );
    });

    test('returns seeded conversations and message history', () async {
      final conversations = await GetConversationsUseCase(repository)();

      expect(conversations, hasLength(4));
      expect(conversations.first.category, 'Driver');
      expect(conversations.first.messages, hasLength(4));
      expect(conversations[2].messages.last.type, 'voice');
    });

    test('selects conversation and appends messages through cubit', () async {
      final cubit = CommunicationCubit(
        getConversations: GetConversationsUseCase(repository),
        addMessage: const AddConversationMessageUseCase(),
      );

      await cubit.load();
      final loaded = cubit.state as CommunicationLoaded;
      cubit.selectConversation(loaded.conversations.first);
      cubit.addMessage(
        ChatMessage(
          id: 'test',
          sender: 'user',
          senderName: 'User',
          text: 'Hello',
          time: 'Now',
        ),
      );

      final state = cubit.state as CommunicationLoaded;
      expect(state.activeConversation?.unreadCount, 0);
      expect(state.activeConversation?.messages.last.text, 'Hello');

      await cubit.close();
    });
  });
}
