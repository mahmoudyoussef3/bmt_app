import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/notifications/domain/entities/client_notification.dart';
import 'package:bmt_app/apps/client/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:bmt_app/apps/client/features/notifications/domain/usecases/mark_all_as_read_usecase.dart';
import 'package:bmt_app/apps/client/features/notifications/domain/usecases/mark_as_read_usecase.dart';
import 'package:bmt_app/apps/client/features/notifications/domain/usecases/watch_notifications_usecase.dart';
import 'package:bmt_app/apps/client/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:bmt_app/apps/client/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:bmt_app/apps/client/features/notifications/presentation/widgets/notification_tile.dart';
import 'package:bmt_app/apps/client/features/notifications/presentation/widgets/notifications_category_bar.dart';

import '../../client_test_app.dart';

ClientNotification _note(
  String id,
  NotificationCategory category, {
  String? actionUrl,
}) {
  return ClientNotification(
    id: id,
    title: 'Title $id',
    body: 'Body $id',
    category: category,
    isRead: false,
    createdAt: DateTime(2026, 7, 23),
    actionUrl: actionUrl,
  );
}

class _FakeNotificationsRepository implements NotificationsRepository {
  _FakeNotificationsRepository(this.items);

  final List<ClientNotification> items;

  @override
  Stream<List<ClientNotification>> watchNotifications() =>
      Stream.value(items);

  @override
  Future<void> markAsRead(String id) async {}

  @override
  Future<void> markAllAsRead() async {}

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

NotificationsCubit _cubit(List<ClientNotification> items) {
  final repository = _FakeNotificationsRepository(items);
  return NotificationsCubit(
    watchNotifications: WatchNotificationsUseCase(repository),
    markAsRead: MarkAsReadUseCase(repository),
    markAllAsRead: MarkAllAsReadUseCase(repository),
  );
}

Future<NotificationsCubit> _pump(
  WidgetTester tester,
  List<ClientNotification> items,
) async {
  final cubit = _cubit(items)..startWatching();
  await tester.pumpWidget(
    clientTestApp(
      BlocProvider<NotificationsCubit>.value(
        value: cubit,
        child: const NotificationsScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return cubit;
}

void main() {
  group('NotificationsScreen', () {
    testWidgets('lists every notification and offers the category filter', (
      tester,
    ) async {
      final cubit = await _pump(tester, [
        _note('1', NotificationCategory.booking),
        _note('2', NotificationCategory.payment),
        _note('3', NotificationCategory.trip),
      ]);

      expect(find.byType(NotificationTile), findsNWidgets(3));
      expect(find.byType(NotificationsCategoryBar), findsOneWidget);
      await cubit.close();
    });

    testWidgets('picking a category narrows the feed to it', (tester) async {
      final cubit = await _pump(tester, [
        _note('1', NotificationCategory.booking),
        _note('2', NotificationCategory.payment),
        _note('3', NotificationCategory.payment),
      ]);

      cubit.filterByCategory(NotificationCategory.payment);
      await tester.pumpAndSettle();

      expect(find.byType(NotificationTile), findsNWidgets(2));
      await cubit.close();
    });

    testWidgets('a category with nothing in it says so without claiming the '
        'inbox is empty', (tester) async {
      final cubit = await _pump(tester, [
        _note('1', NotificationCategory.booking),
      ]);

      cubit.filterByCategory(NotificationCategory.promotion);
      await tester.pumpAndSettle();

      expect(find.byType(NotificationTile), findsNothing);
      expect(find.text('Nothing in this category'), findsOneWidget);
      // The strip must survive, or there is no way back to the full feed.
      expect(find.byType(NotificationsCategoryBar), findsOneWidget);
      await cubit.close();
    });

    testWidgets('an empty inbox shows no filter strip at all', (tester) async {
      final cubit = await _pump(tester, const <ClientNotification>[]);

      expect(find.byType(NotificationsCategoryBar), findsNothing);
      expect(find.text('Nothing in this category'), findsNothing);
      await cubit.close();
    });
  });
}
