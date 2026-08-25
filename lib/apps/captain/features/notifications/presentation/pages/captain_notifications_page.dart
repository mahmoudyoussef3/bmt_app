import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/captain/core/di/captain_di.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_empty_state.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_sliver_header.dart';

import '../../domain/entities/captain_notification.dart';
import '../cubit/captain_notifications_cubit.dart';
import '../cubit/captain_notifications_state.dart';

class CaptainNotificationsPage extends StatelessWidget {
  const CaptainNotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CaptainNotificationsCubit>(
      create: (_) => captainGetIt<CaptainNotificationsCubit>()..startWatching(),
      child: const _CaptainNotificationsView(),
    );
  }
}

class _CaptainNotificationsView extends StatelessWidget {
  const _CaptainNotificationsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CaptainColors.backgroundFor(context),
      body: CustomScrollView(
        slivers: [
          CaptainSliverHeader(
            title: 'الإشعارات',
            actions: [
              BlocBuilder<CaptainNotificationsCubit, CaptainNotificationsState>(
                builder: (context, state) {
                  if (state is CaptainNotificationsLoaded &&
                      state.unreadCount > 0) {
                    return _MarkAllReadButton(
                      onTap: () => context
                          .read<CaptainNotificationsCubit>()
                          .markAllAsRead(),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(width: CaptainDesignTokens.s8),
            ],
          ),
          BlocBuilder<CaptainNotificationsCubit, CaptainNotificationsState>(
            builder: (context, state) => switch (state) {
              CaptainNotificationsLoading() => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              CaptainNotificationsError(:final message) => SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CaptainEmptyState(
                    icon: Icons.wifi_off_rounded,
                    title: 'تعذر تحميل الإشعارات',
                    subtitle: message,
                    action: TextButton(
                      onPressed: () => context
                          .read<CaptainNotificationsCubit>()
                          .startWatching(),
                      child: const Text('إعادة المحاولة'),
                    ),
                  ),
                ),
              ),
              CaptainNotificationsLoaded(:final notifications) =>
                notifications.isEmpty
                    ? const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: CaptainEmptyState(
                            icon: Icons.notifications_none_rounded,
                            title: 'لا توجد إشعارات',
                            subtitle:
                                'كل ما يصلك من العمليات — رحلة جديدة، تغيير '
                                'مركبة، رسالة — سيظهر هنا.',
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          CaptainDesignTokens.s16,
                          CaptainDesignTokens.s12,
                          CaptainDesignTokens.s16,
                          CaptainDesignTokens.s20,
                        ),
                        sliver: SliverList.separated(
                          itemCount: notifications.length,
                          separatorBuilder: (_, index) =>
                              const SizedBox(height: CaptainDesignTokens.s8),
                          itemBuilder: (_, i) => CaptainNotificationTile(
                            notification: notifications[i],
                            onMarkRead: () => context
                                .read<CaptainNotificationsCubit>()
                                .markAsRead(notifications[i].id),
                          ),
                        ),
                      ),
              _ => const SliverToBoxAdapter(child: SizedBox.shrink()),
            },
          ),
        ],
      ),
    );
  }
}

class _MarkAllReadButton extends StatelessWidget {
  const _MarkAllReadButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      child: Text(
        'تعليم الكل كمقروء',
        style: CaptainTypography.labelMedium(context).copyWith(
          color: CaptainColors.primaryInkFor(context),
          letterSpacing: 0,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// One notification, in the design's flat idiom.
///
/// Unread is carried by a single brand dot, not by tinting the whole card. A
/// list where every unread row is a filled blue rectangle has no hierarchy left
/// to say which one is urgent — the dot leaves the card neutral so the
/// emergency glyph beside it is the only coloured thing on the screen.
class CaptainNotificationTile extends StatelessWidget {
  const CaptainNotificationTile({
    super.key,
    required this.notification,
    required this.onMarkRead,
  });

  final CaptainNotification notification;
  final VoidCallback onMarkRead;

  @override
  Widget build(BuildContext context) {
    final muted = CaptainColors.textSecondaryFor(context);
    final isUnread = !notification.isRead;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: notification.isRead ? null : onMarkRead,
        borderRadius: CaptainDesignTokens.br14,
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: CaptainColors.surfaceFor(context),
            borderRadius: CaptainDesignTokens.br14,
            border: CaptainDesignTokens.hairline(context),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(top: 3),
                child: Icon(
                  _categoryIcon(notification.category),
                  size: 20,
                  color: _categoryColor(context, notification.category),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: CaptainTypography.bodySmall(context).copyWith(
                        fontSize: 13.5,
                        color: CaptainColors.textPrimaryFor(context),
                        fontWeight: isUnread
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      notification.body,
                      style: CaptainTypography.labelMedium(context).copyWith(
                        color: muted,
                        letterSpacing: 0,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isUnread) ...[
                const SizedBox(width: CaptainDesignTokens.s8),
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsetsDirectional.only(top: 6),
                  decoration: BoxDecoration(
                    color: CaptainColors.primaryInkFor(context),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _categoryIcon(CaptainNotificationCategory c) => switch (c) {
    CaptainNotificationCategory.trip => Icons.directions_bus_outlined,
    CaptainNotificationCategory.passenger => Icons.people_alt_outlined,
    CaptainNotificationCategory.assignment => Icons.assignment_outlined,
    CaptainNotificationCategory.emergency => Icons.warning_amber_rounded,
    CaptainNotificationCategory.announcement => Icons.campaign_outlined,
    _ => Icons.notifications_outlined,
  };

  Color _categoryColor(BuildContext context, CaptainNotificationCategory c) =>
      c == CaptainNotificationCategory.emergency
      ? CaptainColors.dangerFor(context)
      : CaptainColors.primaryInkFor(context);
}
