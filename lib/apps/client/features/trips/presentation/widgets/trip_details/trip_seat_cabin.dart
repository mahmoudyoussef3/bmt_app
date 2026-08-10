import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/features/trips/domain/entities/trip_seat.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_seat_map.dart';
import 'package:bmt_app/core/widgets/vehicle_seats/vehicle_seats.dart';

/// The Seats section's cabin, shared by the Trip Details preview and the
/// full-screen seat map.
///
/// It used to draw its own bus frame and its own legend around [TripSeatMap].
/// Both now come from the shared seat system, so this is only the choice of how
/// much room the cabin gets in each of the two places it appears.
class TripSeatCabin extends StatelessWidget {
  const TripSeatCabin({
    super.key,
    required this.seats,
    required this.vehicleType,
    this.showLegend = true,
    this.density = SeatLayoutDensity.compact,
  });

  final List<TripSeat> seats;

  /// The trip's vehicle type, which decides the cabin drawn below.
  final String vehicleType;
  final bool showLegend;
  final SeatLayoutDensity density;

  @override
  Widget build(BuildContext context) {
    return TripSeatMap(
      seats: seats,
      vehicleType: vehicleType,
      showLegend: showLegend,
      density: density,
    );
  }
}
