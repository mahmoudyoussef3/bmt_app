import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_cancellation_flow.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_review_flow.dart';

/// Trip Details' sticky bottom action bar — exactly one primary action set
/// per trip status, never a stray duplicate action (a previous version
/// showed a "Track Vehicle" button here for upcoming trips, which cannot be
/// tracked yet since they haven't started).
class TripActionsBar extends StatelessWidget {
  const TripActionsBar({
    super.key,
    required this.trip,
    required this.canCancel,
    required this.canReview,
    required this.canTrack,
  });

  final TripData trip;
  final bool canCancel;
  final bool canReview;
  final bool canTrack;

  @override
  Widget build(BuildContext context) {
    if (!canCancel && !canReview && !canTrack) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: BoxDecoration(
          color: ClientColors.surfaceFor(context).withAlpha(245),
          border: Border(
            top: BorderSide(color: ClientColors.borderFor(context)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(16),
              blurRadius: 20,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canTrack)
              ClientButton(
                label: 'Track Vehicle',
                onPressed: () => Navigator.pushNamed(
                  context,
                  '/tracking',
                  arguments: {'bookingId': trip.id},
                ),
              ),
            if (canCancel)
              ClientButton.secondary(
                label: 'Cancel Trip',
                onPressed: () => showTripCancellationFlow(
                  context,
                  tripReference: trip.reference,
                ),
              ),
            if (canReview)
              Row(
                children: [
                  Expanded(
                    child: ClientButton(
                      label: 'Rate Trip',
                      onPressed: () => showTripReviewFlow(
                        context,
                        tripReference: trip.reference,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ClientButton.secondary(
                      label: 'Book Again',
                      onPressed: () =>
                          Navigator.pushNamed(context, '/booking/search'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
