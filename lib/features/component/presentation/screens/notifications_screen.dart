import 'package:flutter/material.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static final List<_NotificationItem> _notifications = [
    _NotificationItem(
      title: 'Trip Confirmed',
      description:
          'Your trip from Cairo to Banha has been successfully confirmed.',
      time: '5 min ago',
      icon: Icons.check_circle_outline,
      unread: true,
    ),
    _NotificationItem(
      title: 'Driver Arriving Soon',
      description:
          'Your driver will arrive at the pickup point in approximately 10 minutes.',
      time: '15 min ago',
      icon: Icons.directions_bus_outlined,
      unread: true,
    ),
    _NotificationItem(
      title: 'Payment Approved',
      description:
          'Your InstaPay payment has been verified successfully.',
      time: '1 hour ago',
      icon: Icons.payments_outlined,
      unread: false,
    ),
    _NotificationItem(
      title: 'Package Renewal Reminder',
      description:
          'Your monthly package will expire in 3 days.',
      time: 'Yesterday',
      icon: Icons.card_membership_outlined,
      unread: false,
    ),
    _NotificationItem(
      title: 'Reward Points Added',
      description:
          'You earned 50 reward points from your last completed trip.',
      time: '2 days ago',
      icon: Icons.stars_outlined,
      unread: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final notification = _notifications[index];

          return AppCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: scheme.primary.withOpacity(.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    notification.icon,
                    color: scheme.primary,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),

                          Text(
                            notification.time,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Colors.grey,
                                ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Text(
                        notification.description,
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  height: 1.4,
                                ),
                      ),
                    ],
                  ),
                ),

                if (notification.unread) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NotificationItem {
  final String title;
  final String description;
  final String time;
  final IconData icon;
  final bool unread;

  const _NotificationItem({
    required this.title,
    required this.description,
    required this.time,
    required this.icon,
    required this.unread,
  });
}