import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../domain/entities/client_notification.dart';

class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onMarkRead,
  });

  final ClientNotification notification;
  final VoidCallback onTap;
  final VoidCallback onMarkRead;

  @override
  Widget build(BuildContext context) {
    final primary = ClientColors.primaryFor(context);

    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: AlignmentDirectional.centerEnd,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsetsDirectional.only(end: 24),
        decoration: BoxDecoration(
          color: ClientColors.primaryContainerFor(context),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Icon(Icons.done_all_rounded, color: primary),
      ),
      confirmDismiss: (_) async {
        onMarkRead();
        return false;
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: notification.isRead
                ? ClientColors.surfaceFor(context)
                : ClientColors.primaryContainerFor(context).withAlpha(40),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: notification.isRead
                  ? ClientColors.borderFor(context).withAlpha(50)
                  : primary.withAlpha(60),
              width: 1,
            ),
            boxShadow: [
              if (!notification.isRead)
                BoxShadow(
                  color: primary.withAlpha(10),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                )
              else
                BoxShadow(
                  color: ClientColors.shadowFor(context).withAlpha(5),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      notification.title,
                      style: ClientTypography.headingSmall(context).copyWith(
                        fontWeight: notification.isRead
                            ? FontWeight.w600
                            : FontWeight.w800,
                        color: ClientColors.textPrimaryFor(context),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  if (!notification.isRead) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        context.l10n.notifications_newBadge,
                        style: ClientTypography.labelSmall(context).copyWith(
                          color: primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Text(
                notification.body,
                style: ClientTypography.bodyMedium(context).copyWith(
                  color: ClientColors.textSecondaryFor(context).withAlpha(220),
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: ClientColors.textSecondaryFor(context).withAlpha(150),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatDate(context, notification.createdAt),
                    style: ClientTypography.labelMedium(context).copyWith(
                      color: ClientColors.textSecondaryFor(context).withAlpha(150),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat('MMM dd, yyyy • hh:mm a', locale).format(date);
  }
}
