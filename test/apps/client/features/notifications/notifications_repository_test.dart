import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/notifications/data/datasources/supabase_notifications_datasource.dart';
import 'package:bmt_app/apps/client/features/notifications/data/models/client_notification_model.dart';
import 'package:bmt_app/apps/client/features/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:bmt_app/apps/client/features/notifications/domain/entities/client_notification.dart';
import 'package:bmt_app/apps/client/features/notifications/domain/usecases/get_notifications_usecase.dart';

void main() {
  group('Client notifications', () {
    test('returns notification feed data', () async {
      const repository = NotificationsRepositoryImpl(
        _FakeNotificationsDatasource(),
      );

      final notifications = await GetNotificationsUseCase(repository)();

      expect(notifications, hasLength(5));
      expect(notifications.first.title, 'Trip Confirmed');
      expect(
        notifications.where((n) => !n.isRead),
        hasLength(2),
      );
      expect(
        notifications.last.category,
        NotificationCategory.general,
      );
    });
  });
}

class _FakeNotificationsDatasource implements NotificationsDatasource {
  const _FakeNotificationsDatasource();

  @override
  Future<List<ClientNotificationModel>> getNotifications() async {
    final now = DateTime.now();
    return [
      ClientNotificationModel(
        id: 'n1',
        title: 'Trip Confirmed',
        body: 'Your booking has been confirmed.',
        category: NotificationCategory.trip,
        isRead: false,
        createdAt: now,
      ),
      ClientNotificationModel(
        id: 'n2',
        title: 'Payment Received',
        body: 'Your payment has been received.',
        category: NotificationCategory.payment,
        isRead: true,
        createdAt: now,
      ),
      ClientNotificationModel(
        id: 'n3',
        title: 'Driver Assigned',
        body: 'A driver has been assigned to your trip.',
        category: NotificationCategory.trip,
        isRead: false,
        createdAt: now,
      ),
      ClientNotificationModel(
        id: 'n4',
        title: 'Seat Released',
        body: 'Your seat release request was accepted.',
        category: NotificationCategory.booking,
        isRead: true,
        createdAt: now,
      ),
      ClientNotificationModel(
        id: 'n5',
        title: 'Reward Added',
        body: 'You earned a loyalty reward.',
        category: NotificationCategory.general,
        isRead: true,
        createdAt: now,
      ),
    ];
  }

  @override
  Stream<List<ClientNotificationModel>> watchNotifications() =>
      const Stream.empty();

  @override
  Stream<int> watchUnreadCount() => Stream.value(0);

  @override
  Future<void> markAsRead(String id) async {}

  @override
  Future<void> markAllAsRead() async {}
}
