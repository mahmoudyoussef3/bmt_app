import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/notifications/data/datasources/mock_notifications_datasource.dart';
import 'package:bmt_app/apps/client/features/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:bmt_app/apps/client/features/notifications/domain/usecases/get_notifications_usecase.dart';

void main() {
  group('Client notifications', () {
    test('returns notification feed data', () async {
      const repository = NotificationsRepositoryImpl(
        MockNotificationsDatasource(),
      );

      final notifications = await GetNotificationsUseCase(repository)();

      expect(notifications, hasLength(5));
      expect(notifications.first.title, 'Trip Confirmed');
      expect(
        notifications.where((notification) => notification.unread),
        hasLength(2),
      );
      expect(notifications.last.iconKey, 'rewards');
    });
  });
}
