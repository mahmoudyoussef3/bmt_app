import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_premium_panel.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_review_flow.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_soft_icon.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/core/widgets/directional_icon.dart';

/// The tail of a completed trip: an invitation to rate it, or — once the
/// passenger has rated it — a receipt they can tap to re-read what they said.
/// A trip is rated once, so a rated trip must never ask again.
class TripCompletedCard extends StatelessWidget {
  const TripCompletedCard({super.key, required this.trip});

  final TripData trip;

  @override
  Widget build(BuildContext context) {
    final rated = trip.isReviewed;

    return TripPremiumPanel(
      child: InkWell(
        onTap: rated
            ? () => showTripReviewFlow(context, trip: trip.reviewable)
            : null,
        child: Row(
          children: [
            TripSoftIcon(
              icon: rated ? Icons.verified_rounded : Icons.star_rounded,
              color: rated
                  ? ClientColors.journeyCyan
                  : ClientColors.journeyAmber,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                rated
                    ? context.l10n.trips_completedRatedNote
                    : context.l10n.trips_completedRateInvite(trip.driverName),
                style: ClientTypography.bodyMedium(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: ClientColors.textPrimaryFor(context),
                ),
              ),
            ),
            if (rated)
              DirectionalIcon(
                Icons.chevron_right_rounded,
                color: ClientColors.textSecondaryFor(context),
              ),
          ],
        ),
      ),
    );
  }
}
