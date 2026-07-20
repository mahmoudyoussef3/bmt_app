import 'package:flutter/material.dart';

import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../../domain/entities/my_subscription.dart';
import '../details/package_info_panel.dart';
import '../details/package_section_title.dart';

/// Trips used against the package's ride allowance, or an unlimited notice
/// when the Dashboard left the package with no ride cap.
class MySubscriptionTripsCard extends StatelessWidget {
  const MySubscriptionTripsCard({super.key, required this.subscription});

  final MySubscription subscription;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PackageSectionTitle(title: l10n.packages_includedRides),
        const SizedBox(height: 10),
        PackageInfoPanel(
          child: subscription.hasTripLimit
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.mySubscription_tripsUsedOfTotal(
                        subscription.tripsUsed,
                        subscription.tripsTotal,
                      ),
                      style: Theme.of(
                        context,
                      ).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: subscription.tripsRatio,
                        minHeight: 8,
                        backgroundColor: scheme.primary.withAlpha(20),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          scheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.mySubscription_tripsRemaining(
                        subscription.tripsRemaining,
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                )
              : Text(
                  l10n.mySubscription_unlimitedTrips,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
        ),
      ],
    );
  }
}
