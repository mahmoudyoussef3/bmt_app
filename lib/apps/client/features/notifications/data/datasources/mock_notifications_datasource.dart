import '../models/client_notification_model.dart';

class MockNotificationsDatasource {
  const MockNotificationsDatasource();

  Future<List<ClientNotificationModel>> getNotifications() async {
    return const [
      ClientNotificationModel(
        title: 'Trip Confirmed',
        description:
            'Your trip from Cairo to Banha has been successfully confirmed.',
        time: '5 min ago',
        iconKey: 'trip_confirmed',
        unread: true,
      ),
      ClientNotificationModel(
        title: 'Driver Arriving Soon',
        description:
            'Your driver will arrive at the pickup point in approximately 10 minutes.',
        time: '15 min ago',
        iconKey: 'driver_arriving',
        unread: true,
      ),
      ClientNotificationModel(
        title: 'Payment Approved',
        description: 'Your InstaPay payment has been verified successfully.',
        time: '1 hour ago',
        iconKey: 'payment',
        unread: false,
      ),
      ClientNotificationModel(
        title: 'Package Renewal Reminder',
        description: 'Your monthly package will expire in 3 days.',
        time: 'Yesterday',
        iconKey: 'package',
        unread: false,
      ),
      ClientNotificationModel(
        title: 'Reward Points Added',
        description:
            'You earned 50 reward points from your last completed trip.',
        time: '2 days ago',
        iconKey: 'rewards',
        unread: false,
      ),
    ];
  }
}
