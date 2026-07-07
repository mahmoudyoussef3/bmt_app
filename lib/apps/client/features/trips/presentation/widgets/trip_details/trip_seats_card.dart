import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/mini_seat_layout.dart';

/// The passenger's reserved seat(s) for this trip, with a compact seat-map
/// preview.
class TripSeatsCard extends StatelessWidget {
  const TripSeatsCard({super.key, required this.trip});

  final TripData trip;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          trip.seats.isEmpty ? 'No seat selected' : _selectedSeatsText,
          style: ClientTypography.bodyMedium(
            context,
          ).copyWith(
            color: ClientColors.textPrimaryFor(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        if (trip.seats.isNotEmpty) ...[
          const SizedBox(height: 16),
          MiniSeatLayout(
            selectedSeats: trip.seats,
            vehicleName: trip.vehicleName,
          ),
        ],
      ],
    );
  }

  String get _selectedSeatsText {
    if (trip.seats.length == 1) return 'Selected seat: ${trip.seats.first}';
    return 'Selected seats: ${trip.seats.join(', ')}';
  }
}
