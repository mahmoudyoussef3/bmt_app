import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_cancellation_reason_card.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_completed_card.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_detail_section.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_driver_card.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_payment_card.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_seats_card.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_vehicle_card.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

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
    // A trip that never got past `reserved` (needsSupport) is completed on the
    // journey axis but was never travelled on this booking — it must not offer
    // (or dead-end on) a rating invite the attention banner already flags as
    // needing support instead.
    final isCompleted =
        trip.status == TripStatus.completed &&
        (trip.isReviewed || trip.canBeReviewed);

    return Column(
      children: [
        TripDetailSection(
          title: context.l10n.tracking_captain,
          subtitle: trip.isFinished
              ? context.l10n.trips_captainSubtitleFinished
              : context.l10n.trips_captainSubtitleActive,
          icon: Icons.person_pin_circle_rounded,
          child: TripDriverCard(trip: trip),
        ),
        const SizedBox(height: 14),
        TripDetailSection(
          title: context.l10n.tracking_vehicle,
          subtitle: context.l10n.trips_vehicleSubtitle,
          icon: Icons.directions_bus_filled_rounded,
          child: TripVehicleCard(trip: trip),
        ),
        const SizedBox(height: 14),
        TripDetailSection(
          title: context.l10n.common_seats,
          subtitle: context.l10n.trips_seatsSubtitle,
          icon: Icons.event_seat_rounded,
          child: TripSeatsCard(trip: trip),
        ),
        const SizedBox(height: 14),
        TripDetailSection(
          title: context.l10n.payments_stepPayment,
          subtitle: context.l10n.trips_paymentSubtitle,
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
