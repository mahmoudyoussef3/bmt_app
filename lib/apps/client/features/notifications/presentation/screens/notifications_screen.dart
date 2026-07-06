import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/client_notification.dart';
import '../cubit/notifications_cubit.dart';
import '../cubit/notifications_state.dart';
import '../widgets/notification_tile.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationsCubit>().startWatching();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: BlocBuilder<NotificationsCubit, NotificationsState>(
        builder: (context, state) {
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                title: Text('Notifications', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                backgroundColor: cs.surface,
                pinned: true,
                floating: true,
                elevation: 0,
                scrolledUnderElevation: 0,
                centerTitle: true,
                actions: [
                  if (state is NotificationsLoaded && state.unreadCount > 0)
                    TextButton(
                      onPressed: () =>
                          context.read<NotificationsCubit>().markAllAsRead(),
                      child: Text('Mark all read', style: TextStyle(color: cs.primary, fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
              if (state is NotificationsLoaded) ...[
                _buildList(context, state),
              ] else if (state is NotificationsLoading)
                _buildSkeletons()
              else if (state is NotificationsError)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline_rounded,
                            size: 48, color: cs.error),
                        const SizedBox(height: 12),
                        Text(state.message,
                            style: tt.bodyMedium,
                            textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () =>
                              context.read<NotificationsCubit>().startWatching(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(BuildContext context, NotificationsLoaded state) {
    final items = state.notifications;
    if (items.isEmpty) {
      return SliverFillRemaining(child: _EmptyState());
    }
    return SliverPadding(
      padding: const EdgeInsets.only(top: 8, bottom: 40),
      sliver: SliverList.builder(
        itemCount: items.length,
        itemBuilder: (ctx, i) => NotificationTile(
          notification: items[i],
          onTap: () => _handleTap(context, items[i]),
          onMarkRead: () =>
              context.read<NotificationsCubit>().markAsRead(items[i].id),
        ),
      ),
    );
  }

  SliverList _buildSkeletons() => SliverList.builder(
        itemCount: 5,
        itemBuilder: (_, index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHigh.withAlpha(100),
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
      );

  void _handleTap(BuildContext context, ClientNotification n) {
    context.read<NotificationsCubit>().markAsRead(n.id);
    if (n.actionUrl != null && n.actionUrl!.isNotEmpty) {
      Navigator.of(context).pushNamed(n.actionUrl!);
    }
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cs.primary.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.notifications_active_rounded, size: 64,
                  color: cs.primary),
            ),
            const SizedBox(height: 24),
            Text(
              'No notifications yet',
              style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: cs.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Trip updates, booking confirmations and reminders will appear here when they arrive.',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
