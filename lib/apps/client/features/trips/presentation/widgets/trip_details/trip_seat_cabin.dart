import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip_seat.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_seat_legend.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_seat_map.dart';

/// The framed bus cabin — a front/driver indicator above the real seat grid —
/// shared by the Seats section preview and the full-screen seat map.
class TripSeatCabin extends StatelessWidget {
  const TripSeatCabin({
    super.key,
    required this.seats,
    this.seatSize = 44,
    this.showLegend = true,
  });

  final List<TripSeat> seats;
  final double seatSize;
  final bool showLegend;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(54),
          topRight: Radius.circular(54),
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        border: Border.all(color: ClientColors.borderStrongFor(context)),
        boxShadow: ClientElevation.md(context),
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 7,
            decoration: BoxDecoration(
              color: ClientColors.surfaceMutedFor(context),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 14),
          const _CabinFront(),
          const SizedBox(height: 18),
          TripSeatMap(seats: seats, seatSize: seatSize),
          if (showLegend) ...[
            const SizedBox(height: 18),
            const TripSeatLegend(),
          ],
        ],
      ),
    );
  }
}

class _CabinFront extends StatelessWidget {
  const _CabinFront();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: ClientColors.surfaceMutedFor(context),
            shape: BoxShape.circle,
            border: Border.all(color: ClientColors.borderFor(context)),
          ),
          child: const Icon(
            Icons.sports_motorsports_rounded,
            color: ClientColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Front of bus',
          style: ClientTypography.bodySmall(context).copyWith(
            fontWeight: FontWeight.w800,
            color: ClientColors.textSecondaryFor(context),
          ),
        ),
        const Spacer(),
        Icon(
          Icons.sensor_door_rounded,
          size: 18,
          color: ClientColors.textTertiaryFor(context),
        ),
      ],
    );
  }
}
