import 'dart:async';

import 'package:bmt_app/apps/dashboard/features/notifications/domain/entities/operational_alert.dart';
import 'package:bmt_app/apps/dashboard/features/notifications/domain/repositories/operational_alerts_repository.dart';
import 'package:bmt_app/apps/dashboard/features/notifications/domain/usecases/mark_alert_read_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/notifications/domain/usecases/mark_all_alerts_read_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/notifications/domain/usecases/watch_operational_alerts_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/notifications/presentation/cubit/operational_alerts_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/notifications/presentation/cubit/operational_alerts_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeRepo repo;
  late OperationalAlertsCubit cubit;

  OperationalAlert alert(String id, {bool isRead = false}) => OperationalAlert(
    id: id,
    type: OperationalAlertType.paymentReview,
    title: 'مراجعة دفع $id',
    body: 'body',
    isRead: isRead,
    createdAt: DateTime(2026, 7, 6),
  );

  setUp(() {
    repo = _FakeRepo();
    cubit = OperationalAlertsCubit(
      watchAlerts: WatchOperationalAlertsUseCase(repo),
      markAsRead: MarkAlertReadUseCase(repo),
      markAllAsRead: MarkAllAlertsReadUseCase(repo),
    );
  });

  tearDown(() => cubit.close());

  test('emits loading then loaded from the realtime stream', () async {
    cubit.startWatching();
    expect(cubit.state, isA<OperationalAlertsLoading>());

    repo.emit([alert('1'), alert('2')]);
    await Future<void>.delayed(Duration.zero);

    final state = cubit.state as OperationalAlertsLoaded;
    expect(state.alerts.length, 2);
    expect(state.unreadCount, 2);
  });

  test('handles an empty feed', () async {
    cubit.startWatching();
    repo.emit(const []);
    await Future<void>.delayed(Duration.zero);

    final state = cubit.state as OperationalAlertsLoaded;
    expect(state.alerts, isEmpty);
    expect(state.unreadCount, 0);
  });

  test('surfaces stream errors', () async {
    cubit.startWatching();
    repo.emitError('boom');
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state, isA<OperationalAlertsError>());
  });

  test(
    'markAsRead optimistically flips the alert and calls the repo',
    () async {
      cubit.startWatching();
      repo.emit([alert('1'), alert('2')]);
      await Future<void>.delayed(Duration.zero);

      await cubit.markAsRead('1');

      final state = cubit.state as OperationalAlertsLoaded;
      expect(state.unreadCount, 1);
      expect(repo.markedRead, contains('1'));
    },
  );

  test('markAllAsRead clears the unread count', () async {
    cubit.startWatching();
    repo.emit([alert('1'), alert('2')]);
    await Future<void>.delayed(Duration.zero);

    await cubit.markAllAsRead();

    expect((cubit.state as OperationalAlertsLoaded).unreadCount, 0);
    expect(repo.markedAll, isTrue);
  });

  test('filterByType narrows the filtered view', () async {
    cubit.startWatching();
    repo.emit([
      alert('1'),
      OperationalAlert(
        id: '2',
        type: OperationalAlertType.captainRequest,
        title: 'كابتن',
        body: 'body',
        isRead: false,
        createdAt: DateTime(2026, 7, 6),
      ),
    ]);
    await Future<void>.delayed(Duration.zero);

    cubit.filterByType(OperationalAlertType.captainRequest);

    final state = cubit.state as OperationalAlertsLoaded;
    expect(state.filtered.length, 1);
    expect(state.filtered.single.id, '2');
  });
}

class _FakeRepo implements OperationalAlertsRepository {
  final _controller = StreamController<List<OperationalAlert>>.broadcast();
  final List<String> markedRead = [];
  bool markedAll = false;

  void emit(List<OperationalAlert> alerts) => _controller.add(alerts);
  void emitError(Object error) => _controller.addError(error);

  @override
  Stream<List<OperationalAlert>> watchAlerts() => _controller.stream;

  @override
  Stream<int> watchUnreadCount() =>
      _controller.stream.map((rows) => rows.where((a) => !a.isRead).length);

  @override
  Future<void> markAsRead(String id) async => markedRead.add(id);

  @override
  Future<void> markAllAsRead() async => markedAll = true;
}
