import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/captain/features/notifications/domain/entities/captain_notification.dart';
import 'package:bmt_app/apps/captain/features/notifications/domain/repositories/captain_notifications_repository.dart';
import 'package:bmt_app/apps/captain/features/notifications/domain/usecases/mark_all_captain_notifications_read_usecase.dart';
import 'package:bmt_app/apps/captain/features/notifications/domain/usecases/mark_captain_notification_read_usecase.dart';
import 'package:bmt_app/apps/captain/features/notifications/domain/usecases/watch_captain_notifications_usecase.dart';
import 'package:bmt_app/apps/captain/features/notifications/presentation/cubit/captain_notifications_cubit.dart';
import 'package:bmt_app/apps/captain/features/notifications/presentation/cubit/captain_notifications_state.dart';

class _FakeNotificationsRepository implements CaptainNotificationsRepository {
  _FakeNotificationsRepository(this._controller, {this.marksFail = false});

  final StreamController<List<CaptainNotification>> _controller;
  final bool marksFail;
  final List<String> markedRead = [];
  int markAllCalls = 0;

  @override
  Stream<List<CaptainNotification>> watchNotifications() => _controller.stream;

  @override
  Future<void> markAsRead(String id) async {
    if (marksFail) throw Exception('offline');
    markedRead.add(id);
  }

  @override
  Future<void> markAllAsRead() async {
    markAllCalls++;
    if (marksFail) throw Exception('offline');
  }

  @override
  Future<List<CaptainNotification>> getNotifications() async => const [];

  @override
  Stream<int> watchUnreadCount() => const Stream.empty();
}

CaptainNotification _notification(String id, {bool isRead = false}) {
  return CaptainNotification(
    id: id,
    title: 'رحلة جديدة',
    body: 'تم إسناد رحلة إليك',
    category: CaptainNotificationCategory.assignment,
    isRead: isRead,
    createdAt: DateTime(2026, 7, 23),
  );
}

void main() {
  late StreamController<List<CaptainNotification>> controller;
  late _FakeNotificationsRepository repository;

  setUp(() {
    controller = StreamController<List<CaptainNotification>>();
    repository = _FakeNotificationsRepository(controller);
  });

  tearDown(() => controller.close());

  CaptainNotificationsCubit build([
    _FakeNotificationsRepository? withRepository,
  ]) {
    final repo = withRepository ?? repository;
    return CaptainNotificationsCubit(
      watchNotifications: WatchCaptainNotificationsUseCase(repo),
      markAsRead: MarkCaptainNotificationReadUseCase(repo),
      markAllAsRead: MarkAllCaptainNotificationsReadUseCase(repo),
    );
  }

  test('the unread badge counts only unread notifications', () async {
    final cubit = build();
    cubit.startWatching();

    controller.add([
      _notification('a'),
      _notification('b', isRead: true),
      _notification('c'),
    ]);
    await Future<void>.delayed(Duration.zero);

    expect((cubit.state as CaptainNotificationsLoaded).unreadCount, 2);
    await cubit.close();
  });

  test('marking one read greys that row and leaves the rest alone', () async {
    final cubit = build();
    cubit.startWatching();
    controller.add([_notification('a'), _notification('b')]);
    await Future<void>.delayed(Duration.zero);

    await cubit.markAsRead('a');

    final loaded = cubit.state as CaptainNotificationsLoaded;
    expect(loaded.notifications.first.isRead, isTrue);
    expect(loaded.notifications.last.isRead, isFalse);
    expect(repository.markedRead, ['a']);
    await cubit.close();
  });

  test('"read all" clears the badge', () async {
    final cubit = build();
    cubit.startWatching();
    controller.add([_notification('a'), _notification('b')]);
    await Future<void>.delayed(Duration.zero);

    await cubit.markAllAsRead();

    expect((cubit.state as CaptainNotificationsLoaded).unreadCount, 0);
    await cubit.close();
  });

  test('a failed mark-read does not escape as an unhandled error — the tap '
      'handler that fires it never awaits it', () async {
    final failing = _FakeNotificationsRepository(controller, marksFail: true);
    final cubit = build(failing);
    cubit.startWatching();
    controller.add([_notification('a')]);
    await Future<void>.delayed(Duration.zero);

    // Would throw before the guard was added.
    await expectLater(cubit.markAsRead('a'), completes);
    await expectLater(cubit.markAllAsRead(), completes);
    expect(failing.markAllCalls, 1);
    await cubit.close();
  });

  test('a stream failure becomes an error the page can retry from', () async {
    final cubit = build();
    cubit.startWatching();

    controller.addError(Exception('لا يوجد اتصال'));
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state, isA<CaptainNotificationsError>());
    await cubit.close();
  });

  test('emissions arriving after close are dropped rather than thrown', () async {
    final cubit = build();
    cubit.startWatching();
    await cubit.close();

    controller.add([_notification('a')]);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.isClosed, isTrue);
  });
}
