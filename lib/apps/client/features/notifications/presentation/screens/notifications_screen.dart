import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/apps/client/features/notifications/domain/entities/client_notification.dart';
import 'package:bmt_app/apps/client/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:bmt_app/apps/client/features/notifications/presentation/cubit/notifications_state.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/empty_state.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationsCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: BlocBuilder<NotificationsCubit, NotificationsState>(
        builder: (context, state) {
          return switch (state) {
            NotificationsLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            NotificationsError(:final message) => EmptyState(
              title: 'Notifications unavailable',
              subtitle: message,
            ),
            NotificationsLoaded(:final notifications) => ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final notification = notifications[index];

                return AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: scheme.primary.withAlpha(26),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          _iconForNotification(notification),
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
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),

                                Text(
                                  notification.time,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: Colors.grey),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            Text(
                              notification.description,
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(height: 1.4),
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
          };
        },
      ),
    );
  }

  IconData _iconForNotification(ClientNotification notification) {
    return switch (notification.iconKey) {
      'driver_arriving' => Icons.directions_bus_outlined,
      'payment' => Icons.payments_outlined,
      'package' => Icons.card_membership_outlined,
      'rewards' => Icons.stars_outlined,
      'trip_confirmed' || _ => Icons.check_circle_outline,
    };
  }
}
