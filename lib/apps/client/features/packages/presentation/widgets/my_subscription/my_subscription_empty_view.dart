import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Shown when the rider holds no package — either they never bought one, or
/// theirs lapsed between Home loading and this screen opening.
///
/// It keeps the shape of the pass it replaces: a crest, then the explanation,
/// then the one way forward. Buying is not offered here — a plan has no price
/// until a route prices it — so the way forward is a trip.
class MySubscriptionEmptyView extends StatelessWidget {
  const MySubscriptionEmptyView({super.key, required this.onFindTrip});

  /// Sends the rider to pick a trip: a plan is priced against the route it is
  /// bought on, so the booking wizard is where packages are offered.
  final VoidCallback onFindTrip;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(ClientSpacing.lg),
        child: ClientCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ClientColors.primaryContainerFor(context),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.card_membership_rounded,
                  size: 34,
                  color: ClientColors.onPrimaryContainerFor(context),
                ),
              ),
              const SizedBox(height: ClientSpacing.md),
              Text(
                l10n.mySubscription_emptyTitle,
                textAlign: TextAlign.center,
                style: ClientTypography.headingMedium(
                  context,
                ).copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: ClientSpacing.xs),
              Text(
                l10n.mySubscription_emptyBody,
                textAlign: TextAlign.center,
                style: ClientTypography.bodyMedium(
                  context,
                ).copyWith(color: ClientColors.textSecondaryFor(context)),
              ),
              const SizedBox(height: ClientSpacing.md),
              ClientButton(
                label: l10n.mySubscription_findTrip,
                onPressed: onFindTrip,
                icon: const Icon(
                  Icons.search_rounded,
                  size: 19,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
