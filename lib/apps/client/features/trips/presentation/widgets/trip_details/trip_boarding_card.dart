import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/boarding_pass_parts.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_inline_badge.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_soft_icon.dart';

/// A QR-free boarding pass for upcoming/in-progress trips — reference, seat,
/// and board-by details the passenger shows the captain. Replaces the old QR
/// ticket card.
class TripBoardingCard extends StatelessWidget {
  const TripBoardingCard({super.key, required this.trip});

  final TripData trip;

  @override
  Widget build(BuildContext context) {
    final seats = trip.mySeatLabels;
    return Container(
      padding: const EdgeInsets.all(20),
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
                label: trip.status == TripStatus.inProgress
                    ? 'On board'
                    : 'Ready',
                color: ClientColors.journeyGreen,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              BoardingField(label: 'Booking ref', value: trip.reference),
              const SizedBox(width: 16),
              BoardingField(
                label: seats.length > 1 ? 'Seats' : 'Seat',
                value: seats.isEmpty ? '—' : seats.join(', '),
              ),
            ],
          ),
          const TicketPerforation(),
          Row(
            children: [
              Icon(
                Icons.location_on_rounded,
                size: 18,
                color: ClientColors.primaryFor(context),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Board at ${trip.pickup} · ${trip.timeLabel}',
                  style: ClientTypography.bodySmall(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: ClientColors.textSecondaryFor(context),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
