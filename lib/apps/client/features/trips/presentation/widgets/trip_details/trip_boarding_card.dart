import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/boarding_pass_parts.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/ticket_tear_line.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_inline_badge.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_schedule_labels.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_soft_icon.dart';

/// A QR-free boarding pass for upcoming/in-progress trips — the reference, the
/// seat, and where to be, in the order a passenger needs them at the door.
class TripBoardingCard extends StatelessWidget {
  const TripBoardingCard({super.key, required this.trip});

  final TripData trip;

  static const double _padding = 20;

  @override
  Widget build(BuildContext context) {
    final seats = trip.mySeatLabels;
    final onBoard = trip.status == TripStatus.inProgress;

    return Container(
      padding: const EdgeInsets.all(_padding),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const TripSoftIcon(
                icon: Icons.confirmation_number_rounded,
                color: ClientColors.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Boarding pass',
                  style: ClientTypography.headingSmall(context),
                ),
              ),
              TripInlineBadge(
                label: onBoard ? 'On board' : 'Ready',
                color: ClientColors.journeyGreen,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                flex: 3,
                child: BoardingField(
                  label: 'Booking ref',
                  value: trip.reference,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: BoardingField(
                  label: seats.length > 1 ? 'Seats' : 'Seat',
                  value: seats.isEmpty ? '—' : seats.join(', '),
                  emphasis: true,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: TicketTearLine(inset: _padding),
          ),
          BoardingStubLine(
            icon: Icons.location_on_rounded,
            label: 'Board at',
            value: trip.pickup,
          ),
          const SizedBox(height: 10),
          BoardingStubLine(
            icon: Icons.schedule_rounded,
            label: 'Departs',
            value: tripDepartureLabel(context, trip),
          ),
          const SizedBox(height: 14),
          Text(
            onBoard
                ? 'Enjoy your ride — the captain has your seat on the manifest.'
                : 'Show this reference to the captain when you board.',
            style: ClientTypography.bodySmall(
              context,
            ).copyWith(color: ClientColors.textTertiaryFor(context)),
          ),
        ],
      ),
    );
  }
}
