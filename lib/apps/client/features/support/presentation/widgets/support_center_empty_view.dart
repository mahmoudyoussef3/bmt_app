import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'support_home_header.dart';

/// Shown when the client has zero support tickets. The hero above already
/// carries the "Create a ticket" CTA, so this only has to explain the empty
/// list rather than compete with a second button.
class SupportCenterEmptyView extends StatelessWidget {
  const SupportCenterEmptyView({super.key, required this.onCreateTicket});

  final VoidCallback onCreateTicket;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      children: [
        SupportHomeHeader(onCreateTicket: onCreateTicket),
        const SizedBox(height: 40),
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ClientColors.surfaceMutedFor(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.forum_outlined,
                size: 40,
                color: ClientColors.textTertiaryFor(context),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              context.l10n.support_emptyTitle,
              textAlign: TextAlign.center,
              style: ClientTypography.headingSmall(context).copyWith(
                color: ClientColors.textPrimaryFor(context),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.support_emptyBody,
              textAlign: TextAlign.center,
              style: ClientTypography.bodyMedium(context).copyWith(
                color: ClientColors.textSecondaryFor(context),
                height: 1.5,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
