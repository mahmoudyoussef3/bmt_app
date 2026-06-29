import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/client_notification.dart';
import '../cubit/notifications_cubit.dart';
import '../cubit/notifications_state.dart';
import '../widgets/notification_tile.dart';
import '../widgets/notifications_category_bar.dart';

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
      backgroundColor: cs.surfaceContainerLowest,
      body: BlocBuilder<NotificationsCubit, NotificationsState>(
        builder: (context, state) {
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                title: Text('Notifications', style: tt.titleLarge),
                backgroundColor: cs.surface,
                pinned: true,
                floating: true,
                elevation: 0,
                scrolledUnderElevation: 0,
                actions: [
                  if (state is NotificationsLoaded && state.unreadCount > 0)
                    TextButton(
                      onPressed: () =>
                          context.read<NotificationsCubit>().markAllAsRead(),
                      child: const Text('Mark all read'),
                    ),
                ],
              ),
              if (state is NotificationsLoaded) ...[
                SliverToBoxAdapter(
                  child: NotificationsCategoryBar(
                    active: state.activeCategory,
                    onSelect: (cat) =>
                        context.read<NotificationsCubit>().filterByCategory(cat),
                  ),
                ),
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
    final items = state.filtered;
    if (items.isEmpty) {
      return SliverFillRemaining(child: _EmptyState(
        filtered: state.activeCategory != null,
      ));
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      sliver: SliverList.separated(
        itemCount: items.length,
        separatorBuilder: (_, index) => const SizedBox(height: 8),
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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
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
  const _EmptyState({required this.filtered});
  final bool filtered;

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
            Icon(Icons.notifications_none_rounded, size: 56,
                color: cs.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              filtered ? 'No notifications in this category'
                       : 'No notifications yet',
              style: tt.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Trip updates, booking confirmations and reminders will appear here.',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
