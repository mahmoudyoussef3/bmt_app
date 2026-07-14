import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/core/tracking/progress/route_progress_snapshot.dart';

import '../../../domain/entities/tracking_trip.dart';
import '../../formatters/tracking_labels.dart';
import 'tracking_booking_card.dart';
import 'tracking_completed_card.dart';
import 'tracking_crew_card.dart';
import 'tracking_status_header.dart';
import 'tracking_stops_list.dart';

/// The details sheet: status, the rider's own booking, the stops, the crew.
///
/// Each section renders only when it has something real to say — a trip with
/// no readable manifest simply has no booking card, rather than a card full of
/// placeholders. Sections appear in the order a rider asks the questions:
/// "when does it get here?", "where do I get on?", "where is it now?",
/// "who is driving?".
class TrackingSheetBody extends StatelessWidget {
  const TrackingSheetBody({
    super.key,
    required this.trip,
    required this.progress,
    required this.labels,
    required this.onRefresh,
    this.scrollController,
  });

  final TrackingTripData trip;
  final RouteProgressSnapshot? progress;
  final TrackingLabels labels;
  final VoidCallback onRefresh;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final rider = trip.rider;
    final showBooking = rider.hasSeat || rider.hasSegment;

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        const _Grabber(),
        TrackingStatusHeader(
          trip: trip,
          progress: progress,
          labels: labels,
        ),
        if (trip.tripState.isFinished) ...[
          const SizedBox(height: 16),
          TrackingCompletedCard(
            trip: trip,
            labels: labels,
            onReviewed: onRefresh,
          ),
        ],
        if (showBooking) ...[
          const SizedBox(height: 16),
          TrackingBookingCard(rider: rider, labels: labels),
        ],
        if (!trip.tripState.isFinished) ...[
          const SizedBox(height: 20),
          TrackingStopsList(
            progress: progress,
            rider: rider,
            labels: labels,
          ),
        ],
        const SizedBox(height: 16),
        TrackingCrewCard(
          captain: trip.captain,
          vehicle: trip.vehicle,
          labels: labels,
        ),
      ],
    );
  }
}

class _Grabber extends StatelessWidget {
  const _Grabber();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: ClientColors.borderStrongFor(context),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}
