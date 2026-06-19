import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/apps/client/features/notifications/domain/entities/client_notification.dart';
import 'package:bmt_app/apps/client/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:bmt_app/apps/client/features/notifications/presentation/cubit/notifications_state.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_skeleton.dart';
import 'package:bmt_app/apps/client/core/widgets/client_error_card.dart';

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
    return Scaffold(
      backgroundColor: ClientColors.surfaceSubtleFor(context),
      body: BlocBuilder<NotificationsCubit, NotificationsState>(
        builder: (context, state) {
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                title: Text(
                  'Notifications',
                  style: ClientTypography.headingSmall(context),
                ),
                backgroundColor: ClientColors.surfaceFor(context),
                pinned: true,
                floating: true,
                elevation: 0,
                scrolledUnderElevation: 0,
              ),
              switch (state) {
                NotificationsLoading() => SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      ClientSkeleton.notificationItem(),
                      ClientSkeleton.notificationItem(),
                      ClientSkeleton.notificationItem(),
                      ClientSkeleton.notificationItem(),
                    ]),
                  ),
                ),
                NotificationsError(:final message) => SliverFillRemaining(
                  child: ClientErrorCard.fullScreen(
                    message: message,
                    onRetry: () => context.read<NotificationsCubit>().load(),
                  ),
                ),
                NotificationsLoaded(:final notifications) =>
                  notifications.isEmpty
                      ? SliverFillRemaining(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.notifications_none_rounded,
                                    size: 56,
                                    color: ClientColors.textTertiaryFor(
                                      context,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No notifications yet',
                                    style: ClientTypography.headingSmall(
                                      context,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Trip updates, booking confirmations and reminders appear here.',
                                    style: ClientTypography.bodySmall(context)
                                        .copyWith(
                                          color: ClientColors.textTertiaryFor(
                                            context,
                                          ),
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.all(16),
                          sliver: SliverList.separated(
                            itemCount: notifications.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final notification = notifications[index];
                              return _NotificationTile(
                                notification: notification,
                              );
                            },
                          ),
                        ),
              },
            ],
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification});

  final ClientNotification notification;

  @override
  Widget build(BuildContext context) {
    final (iconColor, iconBg, icon) = _resolveIcon(notification.iconKey);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: notification.unread
            ? ClientColors.primaryLight
            : ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notification.unread
              ? ClientColors.primary.withAlpha(40)
              : ClientColors.borderFor(context),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: ClientTypography.labelLarge(
                    context,
                  ).copyWith(color: ClientColors.textPrimaryFor(context)),
                ),
                const SizedBox(height: 4),
                Text(
                  notification.description,
                  style: ClientTypography.bodySmall(
                    context,
                  ).copyWith(color: ClientColors.textSecondaryFor(context)),
                ),
                const SizedBox(height: 6),
                Text(
                  notification.time,
                  style: ClientTypography.labelSmall(
                    context,
                  ).copyWith(color: ClientColors.textTertiaryFor(context)),
                ),
              ],
            ),
          ),
          if (notification.unread) ...[
            const SizedBox(width: 8),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: ClientColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  (Color iconColor, Color iconBg, IconData icon) _resolveIcon(String iconKey) {
    return switch (iconKey) {
      'driver_arriving' => (
        ClientColors.journeyGreen,
        ClientColors.journeyGreenLight,
        Icons.directions_bus_outlined,
      ),
      'payment' => (
        ClientColors.journeyAmber,
        ClientColors.journeyAmberLight,
        Icons.payments_outlined,
      ),
      'package' => (
        ClientColors.journeyPurple,
        ClientColors.journeyPurpleLight,
        Icons.card_membership_outlined,
      ),
      _ => (
        ClientColors.primary,
        ClientColors.primaryLight,
        Icons.check_circle_outline,
      ),
    };
  }
}
