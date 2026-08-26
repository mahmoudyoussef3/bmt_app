import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../domain/entities/client_notification.dart';
import 'notification_icon_resolver.dart';

/// One notification, as the design's inbox row.
///
/// The design draws a compact card — a 12px gutter between a category mark and
/// a title/body/time stack — rather than the tall panel this used to be. The
/// change is not only cosmetic: a rider scanning an inbox is looking for the
/// one line that concerns them, and four rows on screen beat two.
///
/// Unread state is carried by the brand rail and the bolder title, not by a
/// tinted card: tinting the whole surface made a full inbox read as one
/// coloured block with no scanning order left in it.
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
    final unread = !notification.isRead;
    final (iconColor, iconBg, icon) = NotificationIconResolver.resolve(
      context,
      notification.category,
    );

    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: AlignmentDirectional.centerEnd,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        padding: const EdgeInsetsDirectional.only(end: 24),
        decoration: BoxDecoration(
          color: ClientColors.primaryContainerFor(context),
          borderRadius: BorderRadius.circular(ClientRadius.control),
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
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: ClientColors.surfaceFor(context),
            borderRadius: BorderRadius.circular(ClientRadius.control),
            border: Border.all(
              color: unread
                  ? primary.withValues(alpha: 0.45)
                  : ClientColors.borderFor(context),
            ),
            boxShadow: ClientElevation.sm(context),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: ClientTypography.bodyMedium(context)
                                .copyWith(
                                  fontWeight: unread
                                      ? FontWeight.w800
                                      : FontWeight.w700,
                                  color: ClientColors.textPrimaryFor(context),
                                ),
                          ),
                        ),
                        if (unread) ...[
                          const SizedBox(width: 8),
                          Container(
                            margin: const EdgeInsets.only(top: 5),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      notification.body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: ClientTypography.bodySmall(context).copyWith(
                        fontSize: 13,
                        color: ClientColors.textSecondaryFor(context),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (unread) ...[
                          Text(
                            context.l10n.notifications_newBadge,
                            style: ClientTypography.labelSmall(context)
                                .copyWith(
                                  color: primary,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            _formatDate(context, notification.createdAt),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ClientTypography.labelSmall(context)
                                .copyWith(
                                  color: ClientColors.textTertiaryFor(context),
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
