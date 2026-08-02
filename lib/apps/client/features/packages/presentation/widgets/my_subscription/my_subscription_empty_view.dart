import 'package:flutter/material.dart';

import 'package:bmt_app/core/localization/l10n_context.dart';

/// Shown when the rider holds no package — either they never bought one, or
/// theirs lapsed between Home loading and this screen opening.
class MySubscriptionEmptyView extends StatelessWidget {
  const MySubscriptionEmptyView({super.key, required this.onFindTrip});

  /// Sends the rider to pick a trip: a plan is priced against the route it is
  /// bought on, so the booking wizard is where packages are offered.
  final VoidCallback onFindTrip;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.card_membership_rounded,
              size: 56,
              color: scheme.primary.withAlpha(120),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.mySubscription_emptyTitle,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.mySubscription_emptyBody,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onFindTrip,
              child: Text(l10n.mySubscription_findTrip),
            ),
          ],
        ),
      ),
    );
  }
}
