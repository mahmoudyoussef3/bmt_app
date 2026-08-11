import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/widgets/client_seat_labels.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip_seat.dart';
import 'package:bmt_app/core/vehicles/vehicles.dart';
import 'package:bmt_app/core/widgets/vehicle_seats/vehicle_seats.dart';

/// The trip's real seats drawn in the cabin of the vehicle actually assigned to
/// it — resolved from [vehicleType], never guessed from the seat count.
///
/// Read-only: this is a record of a booking, not a booking flow. The rider's
/// own seat is the one highlighted tile, which is the same treatment a selected
/// seat gets while booking, so the seat they picked looks like the seat they
/// got.
class TripSeatMap extends StatelessWidget {
  const TripSeatMap({
    super.key,
    required this.seats,
    required this.vehicleType,
    this.showLegend = false,
    this.density = SeatLayoutDensity.compact,
  });

  final List<TripSeat> seats;
  final String vehicleType;
  final bool showLegend;
  final SeatLayoutDensity density;

  @override
  Widget build(BuildContext context) {
    final ordered = [...seats]
      ..sort((a, b) {
        final rowCompare = a.row.compareTo(b.row);
        return rowCompare != 0 ? rowCompare : a.column.compareTo(b.column);
      });
    final blueprint = VehicleSeatLayouts.resolveRaw(
      vehicleType: vehicleType,
      seats: [for (final seat in ordered) (row: seat.row, column: seat.column)],
    );

    return VehicleSeatLayout(
      blueprint: blueprint,
      seats: [
        for (final seat in ordered)
          VehicleSeatData(
            
            id: '${seat.row}-${seat.column}',
            label: seat.displayLabel,
            state: switch (seat.state) {
              TripSeatState.mine => SeatViewState.selected,
              TripSeatState.occupied => SeatViewState.occupied,
              TripSeatState.available => SeatViewState.available,
            },
            enabled: false,
          ),
      ],
      mode: SeatLayoutMode.readOnly,
      density: density,
      showLegend: showLegend,
      labels: clientSeatLabels(context),
    );
  }
}
