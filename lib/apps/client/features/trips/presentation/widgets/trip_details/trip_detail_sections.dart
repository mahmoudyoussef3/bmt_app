import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_cancellation_reason_card.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_completed_card.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_detail_section.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_driver_card.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_payment_card.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_route_timeline_card.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_seats_card.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_vehicle_card.dart';

/// The Route/Driver/Vehicle/Seats/Payment sections, plus a trailing
/// cancellation-reason or rate-this-trip card when relevant.
class TripDetailSections extends StatelessWidget {
  const TripDetailSections({super.key, required this.trip});

  final TripData trip;

  @override
  Widget build(BuildContext context) {
    final canReview = trip.status == TripStatus.completed;

    return Column(
      children: [
        TripDetailSection(
          title: 'Route',
          subtitle: 'Pickup point and destination',
          icon: Icons.route_rounded,
          child: TripRouteTimelineCard(trip: trip),
        ),
        const SizedBox(height: 16),
        TripDetailSection(
          title: 'Driver',
          subtitle: 'Assigned captain details',
          icon: Icons.person_pin_circle_rounded,
          child: TripDriverCard(trip: trip),
        ),
        const SizedBox(height: 16),
        TripDetailSection(
          title: 'Vehicle',
          subtitle: 'Assigned vehicle details',
          icon: Icons.directions_bus_filled_rounded,
          child: TripVehicleCard(trip: trip),
        ),
        const SizedBox(height: 16),
        TripDetailSection(
          title: 'Seats',
          subtitle: 'Seats reserved for this trip',
          icon: Icons.event_seat_rounded,
          child: TripSeatsCard(trip: trip),
        ),
        const SizedBox(height: 16),
        TripDetailSection(
          title: 'Payment',
          subtitle: 'Payment status and fare',
          icon: Icons.payments_rounded,
          child: TripPaymentCard(trip: trip),
        ),
        if (trip.cancellationReason != null) ...[
          const SizedBox(height: 16),
          TripCancellationReasonCard(reason: trip.cancellationReason!),
        ],
        if (canReview) ...[
          const SizedBox(height: 16),
          TripCompletedCard(trip: trip),
        ],
      ],
    );
  }
}
