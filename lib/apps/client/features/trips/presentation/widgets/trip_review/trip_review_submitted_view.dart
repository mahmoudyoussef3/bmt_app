import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/reviewable_trip.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip_review.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_review/trip_review_rating_card.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/core/widgets/route_direction_text.dart';

/// The passenger's stored review, read-only. Reviewing is a one-time act per
/// trip, so re-opening the sheet confirms what they said rather than inviting
/// them to say it again.
class TripReviewSubmittedView extends StatelessWidget {
  const TripReviewSubmittedView({
    super.key,
    required this.trip,
    required this.review,
  });

  final ReviewableTrip trip;
  final TripReview review;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(
              Icons.verified_rounded,
              color: ClientColors.journeyCyan,
              size: 26,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.l10n.trips_reviewThankYouTitle,
                style: ClientTypography.headingMedium(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          context.l10n.trips_reviewThankYouBody(trip.reference),
          style: ClientTypography.bodySmall(
            context,
          ).copyWith(color: ClientColors.textSecondaryFor(context)),
        ),
        const SizedBox(height: 20),
        TripReviewRatingCard(
          title: context.l10n.trips_ratingDriver,
          subtitle: trip.driverName,
          value: review.driverRating,
        ),
        const SizedBox(height: 16),
        TripReviewRatingCard(
          title: context.l10n.trips_ratingVehicle,
          subtitle: trip.vehicleName,
          value: review.vehicleRating,
        ),
        const SizedBox(height: 16),
        TripReviewRatingCard(
          title: context.l10n.trips_ratingRoute,
          subtitle: trip.hasEndpoints
              ? routeDirectionLabel(
                  trip.origin,
                  trip.destination,
                  direction: Directionality.of(context),
                )
              : trip.routeName,
          value: review.routeRating,
        ),
        if (review.comment.trim().isNotEmpty) ...[
          const SizedBox(height: 16),
          _CommentCard(comment: review.comment.trim()),
        ],
        const SizedBox(height: 20),
        ClientButton.secondary(
          label: context.l10n.payments_close,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({required this.comment});

  final String comment;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.trips_reviewYourFeedbackLabel,
            style: ClientTypography.bodyMedium(
              context,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(comment, style: ClientTypography.bodySmall(context)),
        ],
      ),
    );
  }
}
