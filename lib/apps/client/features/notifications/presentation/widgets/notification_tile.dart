import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: AlignmentDirectional.centerEnd,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsetsDirectional.only(end: 24),
        decoration: BoxDecoration(
          color: cs.primaryContainer,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Icon(Icons.done_all_rounded, color: cs.onPrimaryContainer),
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
            color: notification.isRead ? cs.surface : cs.primaryContainer.withAlpha(40),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: notification.isRead
                  ? cs.outlineVariant.withAlpha(50)
                  : cs.primary.withAlpha(60),
              width: 1,
            ),
            boxShadow: [
              if (!notification.isRead)
                BoxShadow(
                  color: cs.primary.withAlpha(10),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                )
              else
                BoxShadow(
                  color: cs.shadow.withAlpha(5),
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
                      style: tt.titleMedium?.copyWith(
                        fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.w800,
                        color: cs.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  if (!notification.isRead) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: cs.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        context.l10n.notifications_newBadge,
                        style: tt.labelSmall?.copyWith(
                          color: cs.primary,
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
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant.withAlpha(220),
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 14, color: cs.onSurfaceVariant.withAlpha(150)),
                  const SizedBox(width: 6),
                  Text(
                    _formatDate(context, notification.createdAt),
                    style: tt.labelMedium?.copyWith(
                      color: cs.onSurfaceVariant.withAlpha(150),
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
