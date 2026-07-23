import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/captain/features/communication/domain/entities/conversation.dart';
import 'package:bmt_app/apps/captain/features/communication/domain/repositories/communication_repository.dart';
import 'package:bmt_app/apps/captain/features/communication/domain/usecases/get_conversation_usecase.dart';
import 'package:bmt_app/apps/captain/features/communication/domain/usecases/send_message_usecase.dart';
import 'package:bmt_app/apps/captain/features/communication/presentation/cubit/captain_notification_cubit.dart';
import 'package:bmt_app/apps/captain/features/communication/presentation/cubit/communication_cubit.dart';
import 'package:bmt_app/apps/captain/features/communication/presentation/cubit/communication_state.dart';

/// Captain↔operations messaging had no tests at all, and two of the defects it
/// carried were the kind only a test pins down: a bubble that could never
/// identify its own author, and an operations broadcast that re-announced
/// itself on every launch.
class _FakeRepository implements CommunicationRepository {
  _FakeRepository({this.opsMessages = const Stream.empty()});

  final Stream<String> opsMessages;
  final List<({String text, CaptainMessageType type})> sent = [];
  bool failNext = false;

  @override
  Future<CaptainConversation> getConversation({
    required String tripId,
    String? passengerId,
  }) async {
    if (failNext) throw Exception('boom');
    return CaptainConversation(
      id: 'c1',
      title: 'thread',
      messages: const [
        CaptainMessage(
          id: 'm1',
          senderName: 'أنت',
          text: 'في الطريق',
          type: CaptainMessageType.text,
          isMine: true,
        ),
        CaptainMessage(
          id: 'm2',
          senderName: 'العمليات',
          text: 'تمام',
          type: CaptainMessageType.text,
          isMine: false,
        ),
      ],
      passengerId: passengerId,
    );
  }

  @override
  Future<CaptainConversation> sendMessage({
    required String tripId,
    String? passengerId,
    required String text,
    required CaptainMessageType type,
  }) async {
    sent.add((text: text, type: type));
    return getConversation(tripId: tripId, passengerId: passengerId);
  }

  @override
  Stream<String> watchIncomingOpsMessages() => opsMessages;
}

void main() {
  group('conversation cubit', () {
    test('loads a thread and keeps each message\'s authorship', () async {
      final repository = _FakeRepository();
      final cubit = _cubit(repository);

      await cubit.load(tripId: 't1');

      final state = cubit.state as CaptainCommunicationLoaded;
      // The captain's own line sits on their side; operations' does not. This
      // used to be re-derived from the display name, which matched neither
      // label the datasource produces, so every bubble read as incoming.
      expect(state.conversation.messages.first.isMine, isTrue);
      expect(state.conversation.messages.last.isMine, isFalse);
      await cubit.close();
    });

    test('an empty or whitespace message is never sent', () async {
      final repository = _FakeRepository();
      final cubit = _cubit(repository);
      await cubit.load(tripId: 't1');

      await cubit.send('   ', CaptainMessageType.text);

      expect(repository.sent, isEmpty);
      await cubit.close();
    });

    test('a sent message is trimmed before it leaves', () async {
      final repository = _FakeRepository();
      final cubit = _cubit(repository);
      await cubit.load(tripId: 't1');

      await cubit.send('  وصلت المحطة  ', CaptainMessageType.text);

      expect(repository.sent.single.text, 'وصلت المحطة');
      await cubit.close();
    });

    test('a failed load surfaces as an error the screen can retry', () async {
      final repository = _FakeRepository()..failNext = true;
      final cubit = _cubit(repository);

      await cubit.load(tripId: 't1');

      expect(cubit.state, isA<CaptainCommunicationError>());
      await cubit.close();
    });
  });

  group('operations broadcast', () {
    test('the message already on the wire at subscribe time is not '
        're-announced', () async {
      // Supabase replays the newest matching row on subscribe. Treating that
      // as new popped a stale broadcast at the captain on every app launch.
      final controller = StreamController<String>();
      final cubit = CaptainNotificationCubit(
        _FakeRepository(opsMessages: controller.stream),
      );
      final seen = <CaptainNotificationState>[];
      cubit.stream.listen(seen.add);

      cubit.startListening();
      controller.add('بلاغ قديم من الأمس');
      await Future<void>.delayed(Duration.zero);

      expect(seen, isEmpty);
      await controller.close();
      await cubit.close();
    });

    test('a broadcast that arrives after subscribe is announced once', () async {
      final controller = StreamController<String>();
      final cubit = CaptainNotificationCubit(
        _FakeRepository(opsMessages: controller.stream),
      );
      final seen = <CaptainNotificationState>[];
      cubit.stream.listen(seen.add);

      cubit.startListening();
      controller.add('بلاغ قديم');
      await Future<void>.delayed(Duration.zero);
      controller.add('تحويلة على الطريق الصحراوي');
      await Future<void>.delayed(Duration.zero);
      // The same body arriving twice is one announcement, not two.
      controller.add('تحويلة على الطريق الصحراوي');
      await Future<void>.delayed(Duration.zero);

      expect(seen, hasLength(1));
      expect(
        (seen.single as CaptainNotificationReceived).message,
        'تحويلة على الطريق الصحراوي',
      );
      await controller.close();
      await cubit.close();
    });
  });
}

CaptainCommunicationCubit _cubit(CommunicationRepository repository) {
  return CaptainCommunicationCubit(
    getConversation: GetConversationUseCase(repository),
    sendMessage: SendMessageUseCase(repository),
  );
}
