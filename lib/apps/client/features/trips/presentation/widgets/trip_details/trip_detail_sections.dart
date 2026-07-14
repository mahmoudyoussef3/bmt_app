import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_cancellation_reason_card.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_completed_card.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_detail_section.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_driver_card.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_payment_card.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_seats_card.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_vehicle_card.dart';

/// The Driver/Vehicle/Seats/Payment sections, plus a trailing
/// cancellation-reason or rate-this-trip card when relevant.
///
/// There is deliberately no Route section: pickup, drop-off and departure now
/// live once, in the hero. The old Route card restated all three a screen
/// below them.
class TripDetailSections extends StatelessWidget {
  const TripDetailSections({super.key, required this.trip});

  final TripData trip;

  @override
  Widget build(BuildContext context) {
    final isCompleted = trip.status == TripStatus.completed;

    return Column(
      children: [
        TripDetailSection(
          title: 'Captain',
          subtitle: trip.isFinished ? 'Who drove you' : 'Who is driving you',
          icon: Icons.person_pin_circle_rounded,
          child: TripDriverCard(trip: trip),
        ),
        const SizedBox(height: 14),
        TripDetailSection(
          title: 'Vehicle',
          subtitle: 'The bus on this trip',
          icon: Icons.directions_bus_filled_rounded,
          child: TripVehicleCard(trip: trip),
        ),
        const SizedBox(height: 14),
        TripDetailSection(
          title: 'Seats',
          subtitle: 'Your seats on the cabin map',
          icon: Icons.event_seat_rounded,
          child: TripSeatsCard(trip: trip),
        ),
        const SizedBox(height: 14),
        TripDetailSection(
          title: 'Payment',
          subtitle: 'Status and fare breakdown',
          icon: Icons.payments_rounded,
          child: TripPaymentCard(trip: trip),
        ),
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
