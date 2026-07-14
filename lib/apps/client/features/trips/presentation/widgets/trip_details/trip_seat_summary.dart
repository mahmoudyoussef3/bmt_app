import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// The headline for the Seats section: the passenger's own seat(s) on the
/// left, live cabin availability on the right.
class TripSeatSummary extends StatelessWidget {
  const TripSeatSummary({
    super.key,
    required this.mySeatLabels,
    required this.availableSeats,
    required this.totalSeats,
  });

  final List<String> mySeatLabels;
  final int availableSeats;
  final int totalSeats;

  @override
  Widget build(BuildContext context) {
    final hasSeats = mySeatLabels.isNotEmpty;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: ClientColors.journeyCyan.withAlpha(28),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(
            Icons.event_seat_rounded,
            color: ClientColors.journeyCyan,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hasSeats
                    ? (mySeatLabels.length == 1 ? 'Your seat' : 'Your seats')
                    : 'Seat pending',
                style: ClientTypography.bodySmall(context).copyWith(
                  color: ClientColors.textSecondaryFor(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                hasSeats ? mySeatLabels.join(', ') : 'Awaiting confirmation',
                style: ClientTypography.headingSmall(
                  context,
                ).copyWith(color: ClientColors.textPrimaryFor(context)),
              ),
            ],
          ),
        ),
        if (totalSeats > 0)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$availableSeats of $totalSeats',
                style: ClientTypography.bodyMedium(context).copyWith(
                  fontWeight: FontWeight.w900,
                  color: ClientColors.textPrimaryFor(context),
                ),
              ),
              Text(
                'seats free',
                style: ClientTypography.bodySmall(
                  context,
                ).copyWith(color: ClientColors.textSecondaryFor(context)),
              ),
            ],
          ),
      ],
    );
  }
}
