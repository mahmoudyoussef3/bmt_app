import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../../domain/entities/my_subscription.dart';
import '../package_section_title.dart';

/// Rides spent against the package's allowance — or an unlimited notice when
/// the Dashboard left the package with no ride cap.
///
/// Laid out to mirror the validity block above it: the same heading, the same
/// meter, the same "used of total" phrasing. The two things a package can run
/// out of are read the same way.
class MySubscriptionTripsCard extends StatelessWidget {
  const MySubscriptionTripsCard({super.key, required this.subscription});

  final MySubscription subscription;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PackageSectionTitle(
          icon: Icons.confirmation_number_rounded,
          title: l10n.packages_includedRides,
        ),
        const SizedBox(height: ClientSpacing.sm),
        ClientCard(
          padding: const EdgeInsets.all(ClientSpacing.md),
          child: subscription.hasTripLimit
              ? _Allowance(subscription: subscription)
              : const _Unlimited(),
        ),
      ],
    );
  }
}

class _Allowance extends StatelessWidget {
  const _Allowance({required this.subscription});

  final MySubscription subscription;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                l10n.mySubscription_tripsUsedOfTotal(
                  subscription.tripsUsed,
                  subscription.tripsTotal,
                ),
                style: ClientTypography.headingSmall(
                  context,
                ).copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: ClientSpacing.xs),
            _RemainingPill(count: subscription.tripsRemaining),
          ],
        ),
        const SizedBox(height: ClientSpacing.sm),
        ClientMeter(value: subscription.tripsRatio),
      ],
    );
  }
}

/// What is left, stamped rather than written as a footnote: it is the figure a
/// rider checks before deciding whether to book with the package or pay a fare.
class _RemainingPill extends StatelessWidget {
  const _RemainingPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    // A spent allowance stops being brand-blue: the package is still valid, but
    // there is nothing left to draw on, and the pill must not say otherwise.
    final spent = count == 0;
    final ink = spent
        ? ClientColors.journeyAmberFor(context)
        : ClientColors.onPrimaryContainerFor(context);
    final fill = spent
        ? ClientColors.journeyAmberLightFor(context)
        : ClientColors.primaryContainerFor(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(ClientRadius.pill),
      ),
      child: Text(
        context.l10n.mySubscription_tripsRemaining(count),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: ClientTypography.labelMedium(
          context,
        ).copyWith(color: ink, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _Unlimited extends StatelessWidget {
  const _Unlimited();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ClientColors.primaryContainerFor(context),
            borderRadius: BorderRadius.circular(ClientRadius.sm),
          ),
          child: Icon(
            Icons.all_inclusive_rounded,
            size: 20,
            color: ClientColors.onPrimaryContainerFor(context),
          ),
        ),
        const SizedBox(width: ClientSpacing.sm),
        Expanded(
          child: Text(
            context.l10n.mySubscription_unlimitedTrips,
            style: ClientTypography.headingSmall(
              context,
            ).copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}
