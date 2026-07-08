import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/features/trips/domain/entities/trip_seat.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_seat_tile.dart';

/// Any real seats beyond the standard 14-seat cabin shape, laid out as a
/// simple centred wrap rather than a fixed row.
class TripExtraSeats extends StatelessWidget {
  const TripExtraSeats({super.key, required this.seats, required this.seatSize});

  final List<TripSeat> seats;
  final double seatSize;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: seatSize * 0.18,
      runSpacing: seatSize * 0.18,
      alignment: WrapAlignment.center,
      children: [
        for (final seat in seats) TripSeatTile(seat: seat, size: seatSize),
      ],
    );
  }
}
