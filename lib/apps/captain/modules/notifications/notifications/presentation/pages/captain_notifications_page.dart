import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/captain_notification.dart';
import '../cubit/captain_notifications_cubit.dart';
import '../cubit/captain_notifications_state.dart';

class CaptainNotificationsPage extends StatefulWidget {
  const CaptainNotificationsPage({super.key});

  @override
  State<CaptainNotificationsPage> createState() =>
      _CaptainNotificationsPageState();
}

class _CaptainNotificationsPageState extends State<CaptainNotificationsPage> {
  @override
  void initState() {
    super.initState();
    context.read<CaptainNotificationsCubit>().startWatching();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        backgroundColor: cs.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          BlocBuilder<CaptainNotificationsCubit, CaptainNotificationsState>(
            builder: (context, state) {
              if (state is CaptainNotificationsLoaded &&
                  state.unreadCount > 0) {
                return TextButton(
                  onPressed: () =>
                      context.read<CaptainNotificationsCubit>().markAllAsRead(),
                  child: const Text('قراءة الكل'),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<CaptainNotificationsCubit, CaptainNotificationsState>(
        builder: (context, state) => switch (state) {
          CaptainNotificationsLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
          CaptainNotificationsError(:final message) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline_rounded, size: 48, color: cs.error),
                  const SizedBox(height: 12),
                  Text(message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context
                        .read<CaptainNotificationsCubit>()
                        .startWatching(),
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            ),
          CaptainNotificationsLoaded(:final notifications) =>
            notifications.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.notifications_none_rounded, size: 56),
                        SizedBox(height: 12),
                        Text('لا توجد إشعارات'),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: notifications.length,
                    separatorBuilder: (_, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (_, i) => _CaptainNotifTile(
                      notification: notifications[i],
                      onMarkRead: () => context
                          .read<CaptainNotificationsCubit>()
                          .markAsRead(notifications[i].id),
                    ),
                  ),
          _ => const SizedBox.shrink(),
        },
      ),
    );
  }
}

class _CaptainNotifTile extends StatelessWidget {
  const _CaptainNotifTile({
    required this.notification,
    required this.onMarkRead,
  });

  final CaptainNotification notification;
  final VoidCallback onMarkRead;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: notification.isRead ? null : onMarkRead,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notification.isRead
              ? cs.surface
              : cs.primaryContainer.withAlpha(60),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: notification.isRead
                ? cs.outlineVariant
                : cs.primary.withAlpha(50),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_categoryIcon(notification.category),
                color: cs.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notification.title,
                      style: tt.labelLarge?.copyWith(
                        fontWeight: notification.isRead
                            ? FontWeight.w500
                            : FontWeight.w700,
                      )),
                  const SizedBox(height: 3),
                  Text(notification.body,
                      style: tt.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: cs.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(CaptainNotificationCategory c) => switch (c) {
        CaptainNotificationCategory.trip => Icons.directions_bus_outlined,
        CaptainNotificationCategory.passenger =>
          Icons.people_alt_outlined,
        CaptainNotificationCategory.assignment =>
          Icons.assignment_outlined,
        CaptainNotificationCategory.emergency =>
          Icons.warning_amber_rounded,
        CaptainNotificationCategory.announcement =>
          Icons.campaign_outlined,
        _ => Icons.notifications_outlined,
      };
}
