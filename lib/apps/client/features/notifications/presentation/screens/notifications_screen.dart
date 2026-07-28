import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../domain/entities/client_notification.dart';
import '../../domain/entities/notification_destination.dart';
import '../cubit/notifications_cubit.dart';
import '../cubit/notifications_state.dart';
import '../widgets/notification_tile.dart';
import '../widgets/notifications_category_bar.dart';
import '../widgets/notifications_empty_view.dart';

/// The passenger's notification inbox.
///
/// The feed is a live subscription rather than a fetch, so the only thing this
/// screen decides is which of loading / error / loaded to render.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  /// Opens whatever the notification is actually about.
  ///
  /// The destination comes from the row's own `type` and `data` rather than from
  /// `action_url`, which no backend writer populates — see
  /// [resolveNotificationDestination]. Passing the resolved arguments is the
  /// part that matters: a bare push to Trip Details opens *the newest booking*,
  /// not the one the notification names.
  ///
  /// A server-supplied `action_url` still wins when present; an unrecognised
  /// value is absorbed by the app's `onUnknownRoute`, so a stale row can never
  /// crash a tap.
  void _handleTap(BuildContext context, ClientNotification notification) {
    context.read<NotificationsCubit>().markAsRead(notification.id);
    final destination = resolveNotificationDestination(notification);
    if (destination == null) return;
    Navigator.of(
      context,
    ).pushNamed(destination.route, arguments: destination.arguments);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ClientColors.backgroundFor(context),
      body: BlocBuilder<NotificationsCubit, NotificationsState>(
        builder: (context, state) => CustomScrollView(
          slivers: [
            ClientSliverAppBar(
              title: context.l10n.common_notifications,
              floating: true,
              backgroundColor: ClientColors.backgroundFor(context),
              actions: [
                if (state is NotificationsLoaded && state.unreadCount > 0)
                  TextButton(
                    onPressed: () =>
                        context.read<NotificationsCubit>().markAllAsRead(),
                    style: TextButton.styleFrom(
                      foregroundColor: ClientColors.primaryFor(context),
                      textStyle: ClientTypography.labelMedium(context),
                    ),
                    child: Text(context.l10n.notifications_markAllRead),
                  ),
              ],
            ),
            // The category strip only appears once there is something to
            // filter — an empty inbox with seven filter chips over it is
            // noise, not navigation.
            if (state case NotificationsLoaded(:final notifications)
                when notifications.isNotEmpty)
              SliverToBoxAdapter(
                child: NotificationsCategoryBar(
                  active: state.activeCategory,
                  onSelect: context
                      .read<NotificationsCubit>()
                      .filterByCategory,
                ),
              ),
            switch (state) {
              NotificationsLoaded(:final notifications)
                  when notifications.isEmpty =>
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: NotificationsEmptyView(),
                ),
              NotificationsLoaded(:final filtered) when filtered.isEmpty =>
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: NotificationsEmptyView(isFiltered: true),
                ),
              NotificationsLoaded(:final filtered) => SliverPadding(
                padding: const EdgeInsets.only(top: 4, bottom: 40),
                sliver: SliverList.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) => NotificationTile(
                    notification: filtered[index],
                    onTap: () => _handleTap(context, filtered[index]),
                    onMarkRead: () => context
                        .read<NotificationsCubit>()
                        .markAsRead(filtered[index].id),
                  ),
                ),
              ),
              NotificationsError(:final message) => SliverFillRemaining(
                hasScrollBody: false,
                child: ClientErrorCard.fullScreen(
                  message: message,
                  retryLabel: context.l10n.common_retry,
                  onRetry: () =>
                      context.read<NotificationsCubit>().startWatching(),
                ),
              ),
              _ => SliverList.builder(
                itemCount: 6,
                itemBuilder: (_, _) => ClientSkeleton.notificationItem(),
              ),
            },
          ],
        ),
      ),
    );
  }
}
