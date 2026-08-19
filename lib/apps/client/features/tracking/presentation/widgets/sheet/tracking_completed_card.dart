import 'package:bmt_app/apps/client/features/booking/presentation/routes/booking_routes.dart';
import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/reviewable_trip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_review_flow.dart';

import '../../../domain/entities/tracking_trip.dart';
import '../../formatters/tracking_labels.dart';

/// What a finished trip offers the rider.
///
/// The rating here opens the *real* review flow — the one backed by the
/// `submit_trip_review` RPC, keyed on this booking. The screen previously drew
/// its own star rows whose values were held in cubit state and never sent
/// anywhere: the rider rated their captain and nothing happened.
class TrackingCompletedCard extends StatelessWidget {
  const TrackingCompletedCard({
    super.key,
    required this.trip,
    required this.labels,
    required this.onReviewed,
  });

  final TrackingTripData trip;
  final TrackingLabels labels;

  /// Refetches after the sheet closes, so the CTA flips to "already rated".
  final VoidCallback onReviewed;

  @override
  Widget build(BuildContext context) {
    final l10n = labels.l10n;

    return ClientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: ClientColors.journeyCyanFor(context),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.tracking_completedTitle,
                  style: ClientTypography.headingSmall(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (trip.hasReview)
            Text(
              l10n.tracking_alreadyReviewed,
              style: ClientTypography.bodySmall(
                context,
              ).copyWith(color: ClientColors.textSecondaryFor(context)),
            )
          else
            ClientButton(
              label: l10n.tracking_rateTrip,
              icon: const Icon(Icons.star_rounded, size: 20),
              onPressed: () => _review(context),
            ),
          const SizedBox(height: 10),
          ClientButton.secondary(
            label: l10n.tracking_bookAgain,
            onPressed: () =>
                Navigator.of(context).pushNamed(BookingRoutes.search),
          ),
        ],
      ),
    );
  }

  Future<void> _review(BuildContext context) async {
    final bookingId = trip.bookingId;
    if (bookingId == null) return;

    await showTripReviewFlow(
      context,
      trip: ReviewableTrip(
        bookingId: bookingId,
        
        isCompleted: trip.tripState.isFinished,
        reference: trip.tripCode ?? '',
        driverName: trip.captain.displayName ?? '',
        vehicleName: trip.vehicle.displayName ?? '',
        routeLine: _routeLine(),
      ),
    );
    onReviewed();
  }

  String _routeLine() {
    final from = trip.rider.boardingName ?? trip.originName;
    final to = trip.rider.dropoffName ?? trip.destinationName;
    if (from == null || to == null) return trip.routeName ?? '';
    return '$from → $to';
  }
}
