import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Shown when the inbox has nothing to list — a calm "you're all caught up",
/// not an error. Nothing here is actionable, so it carries no button.
///
/// [isFiltered] separates "no notifications at all" from "none in the category
/// you picked": the second is one tap away from content, and saying the same
/// thing for both would read as if the filter had broken the inbox.
class NotificationsEmptyView extends StatelessWidget {
  const NotificationsEmptyView({super.key, this.isFiltered = false});

  final bool isFiltered;

  @override
  Widget build(BuildContext context) {
    final primary = ClientColors.primaryFor(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(ClientSpacing.md),
              decoration: BoxDecoration(
                color: primary.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isFiltered
                    ? Icons.filter_alt_off_rounded
                    : Icons.notifications_none_rounded,
                size: 56,
                color: primary,
              ),
            ),
            const SizedBox(height: ClientSpacing.md),
            Text(
              isFiltered
                  ? context.l10n.notifications_categoryEmptyTitle
                  : context.l10n.notifications_emptyTitle,
              textAlign: TextAlign.center,
              style: ClientTypography.headingMedium(context),
            ),
            const SizedBox(height: ClientSpacing.xs),
            Text(
              isFiltered
                  ? context.l10n.notifications_categoryEmptyBody
                  : context.l10n.notifications_emptyBody,
              textAlign: TextAlign.center,
              style: ClientTypography.bodyMedium(
                context,
              ).copyWith(color: ClientColors.textSecondaryFor(context)),
            ),
          ],
        ),
      ),
    );
  }
}
