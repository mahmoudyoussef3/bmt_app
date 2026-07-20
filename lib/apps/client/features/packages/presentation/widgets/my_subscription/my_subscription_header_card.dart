import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/core/widgets/badge.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

import '../../../domain/entities/my_subscription.dart';

/// The hero card at the top of the screen: package, route, and whether the
/// subscription is still active.
class MySubscriptionHeaderCard extends StatelessWidget {
  const MySubscriptionHeaderCard({super.key, required this.subscription});

  final MySubscription subscription;

  String _statusLabel(AppLocalizations l10n) => switch (subscription.status) {
    'active' => l10n.mySubscription_statusActive,
    'expired' => l10n.mySubscription_statusExpired,
    _ => l10n.mySubscription_statusPending,
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final isActive = subscription.status == 'active';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primary.withAlpha(30),
            scheme.secondary.withAlpha(10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(ClientRadius.lg),
        border: Border.all(color: scheme.primary.withAlpha(60)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subscription.packageName,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                if (subscription.routeName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subscription.routeName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ClientColors.textSecondaryFor(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: ClientSpacing.xs),
          AppBadge(
            text: _statusLabel(l10n),
            color: isActive ? null : scheme.error,
          ),
        ],
      ),
    );
  }
}
