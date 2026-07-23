import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip_seat.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_seat_legend.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_seat_map.dart';

/// The framed bus cabin — matches the booking flow's seat-selection shape —
/// shared by the Seats section preview and the full-screen seat map.
class TripSeatCabin extends StatelessWidget {
  const TripSeatCabin({
    super.key,
    required this.seats,
    required this.vehicleType,
    this.seatSize = 44,
    this.showLegend = true,
  });

  final List<TripSeat> seats;

  /// The trip's vehicle type, which decides the cabin drawn below.
  final String vehicleType;
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
          TripSeatMap(
            seats: seats,
            vehicleType: vehicleType,
            seatSize: seatSize,
          ),
          if (showLegend) ...[
            const SizedBox(height: 18),
            const TripSeatLegend(),
          ],
        ],
      ),
    );
  }
}
