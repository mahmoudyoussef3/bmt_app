import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_seat_map.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip_seat.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_driver_seat_tile.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_extra_seats.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_seat_tile.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/core/vehicles/vehicles.dart';

/// Lays real [TripSeat]s out in the cabin of the vehicle actually assigned to
/// the trip — resolved from [vehicleType], never guessed from the seat count.
/// Seats beyond the blueprint's capacity spill into [TripExtraSeats].
class TripSeatMap extends StatelessWidget {
  const TripSeatMap({
    super.key,
    required this.seats,
    required this.vehicleType,
    this.seatSize = 44,
  });

  final List<TripSeat> seats;
  final String vehicleType;
  final double seatSize;

  @override
  Widget build(BuildContext context) {
    final ordered = [...seats]..sort((a, b) {
      final rowCompare = a.row.compareTo(b.row);
      return rowCompare != 0 ? rowCompare : a.column.compareTo(b.column);
    });
    final blueprint = VehicleSeatLayouts.resolveRaw(
      vehicleType: vehicleType,
      seats: [for (final seat in ordered) (row: seat.row, column: seat.column)],
    );

    return Column(
      children: [
        ClientSeatMap(
          blueprint: blueprint,
          slotWidth: seatSize,
          centerRows: true,
          gap: seatSize * 0.13,
          rowGap: seatSize * 0.16,
          aisleGap: seatSize * 0.55,
          seatBuilder: (context, slot) => _slot(ordered, slot),
          decorationBuilder: (context, slot) => _decoration(context, slot),
        ),
        SizedBox(height: seatSize * 0.13),
        Text(
          context.l10n.trips_seatMapDriverLabel.toUpperCase(),
          style: ClientTypography.labelSmall(context).copyWith(
            color: ClientColors.textTertiaryFor(context),
            letterSpacing: 1.2,
          ),
        ),
        if (ordered.length > blueprint.capacity) ...[
          SizedBox(height: seatSize * 0.23),
          TripExtraSeats(
            seats: ordered.skip(blueprint.capacity).toList(),
            seatSize: seatSize,
          ),
        ],
      ],
    );
  }

  Widget _slot(List<TripSeat> ordered, SeatSlot slot) {
    final index = slot.seatNumber - 1;
    if (index < 0 || index >= ordered.length) {
      return SizedBox(width: seatSize, height: seatSize);
    }
    return TripSeatTile(seat: ordered[index], size: seatSize);
  }

  Widget _decoration(BuildContext context, SeatSlot slot) {
    if (slot.kind == SeatSlotKind.door) {
      return _CabinDoorTile(size: seatSize);
    }
    return TripDriverSeatTile(
      size: seatSize,
      label: slot.label.isEmpty ? 'A' : slot.label,
    );
  }
}

class _CabinDoorTile extends StatelessWidget {
  const _CabinDoorTile({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: ClientColors.surfaceSubtleFor(context),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Icon(
        Icons.sensor_door_outlined,
        size: size * 0.45,
        color: ClientColors.textTertiaryFor(context),
      ),
    );
  }
}
