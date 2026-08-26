import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_cancellation_reason_card.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_completed_card.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_crew_card.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_payment_card.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_stations_card.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_vehicle_card.dart';

/// Everything below the hero: the captain, the bus, the road it takes, what the
/// trip cost, then — when there is one — the cancellation reason or the
/// rate-this-trip card.
///
/// Captain, vehicle and seats used to own a titled card each, and every one of
/// them spent a full screen on one or two facts. The captain is a row and stays
/// one; the bus and the corridor earn their headers, because each is a block of
/// facts rather than a single one. The seat map is still gone: the hero already
/// names the seat.
class TripDetailSections extends StatelessWidget {
  const TripDetailSections({super.key, required this.trip});

  final TripData trip;

  @override
  Widget build(BuildContext context) {
    final isCompleted =
        trip.status == TripStatus.completed &&
        (trip.isReviewed || trip.canBeReviewed);

    return Column(
      children: [
        TripCrewCard(trip: trip),
        const SizedBox(height: 14),
        TripVehicleCard(trip: trip),
        if (trip.hasStops) ...[
          const SizedBox(height: 14),
          TripStationsCard(trip: trip),
        ],
        const SizedBox(height: 14),
        TripPaymentCard(trip: trip),
        if (trip.cancellationReason != null) ...[
          const SizedBox(height: 14),
          TripCancellationReasonCard(reason: trip.cancellationReason!),
        ],
        if (isCompleted) ...[
          const SizedBox(height: 14),
          TripCompletedCard(trip: trip),
        ],
      ],
    );
  }
}
