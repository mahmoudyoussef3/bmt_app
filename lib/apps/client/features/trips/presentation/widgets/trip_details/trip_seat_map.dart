import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip_seat.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_driver_seat_tile.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_extra_seats.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_seat_tile.dart';

/// Lays real [TripSeat]s out in the same cabin shape the passenger picked
/// from while booking: two driver seats up front, three-across rows split by
/// a centre aisle, then a flush four-seat back row. Seats beyond the
/// standard 14-seat layout spill into [TripExtraSeats] underneath.
class TripSeatMap extends StatelessWidget {
  const TripSeatMap({super.key, required this.seats, this.seatSize = 44});

  final List<TripSeat> seats;
  final double seatSize;

  @override
  Widget build(BuildContext context) {
    final ordered = [...seats]..sort((a, b) {
      final rowCompare = a.row.compareTo(b.row);
      return rowCompare != 0 ? rowCompare : a.column.compareTo(b.column);
    });
    TripSeat? seatAt(int index) => index < ordered.length ? ordered[index] : null;
    final gap = seatSize * 0.13;
    final aisle = seatSize * 0.55;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TripDriverSeatTile(size: seatSize, label: 'A1'),
            SizedBox(width: gap),
            TripDriverSeatTile(size: seatSize, label: 'A2'),
            SizedBox(width: aisle),
            _SeatSlot(seat: seatAt(0), size: seatSize),
          ],
        ),
        SizedBox(height: seatSize * 0.13),
        Text(
          'DRIVER',
          style: ClientTypography.labelSmall(context).copyWith(
            color: ClientColors.textTertiaryFor(context),
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: seatSize * 0.23),
        Divider(color: ClientColors.borderFor(context)),
        SizedBox(height: seatSize * 0.1),
        for (final start in [1, 4, 7])
          Padding(
            padding: EdgeInsets.only(top: seatSize * 0.16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SeatSlot(seat: seatAt(start), size: seatSize),
                SizedBox(width: gap),
                _SeatSlot(seat: seatAt(start + 1), size: seatSize),
                SizedBox(width: aisle),
                _SeatSlot(seat: seatAt(start + 2), size: seatSize),
              ],
            ),
          ),
        Padding(
          padding: EdgeInsets.only(top: seatSize * 0.16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 10; i <= 13; i++) ...[
                if (i > 10) SizedBox(width: gap),
                _SeatSlot(seat: seatAt(i), size: seatSize),
              ],
            ],
          ),
        ),
        if (ordered.length > 14) ...[
          SizedBox(height: seatSize * 0.23),
          TripExtraSeats(seats: ordered.skip(14).toList(), seatSize: seatSize),
        ],
      ],
    );
  }
}

class _SeatSlot extends StatelessWidget {
  const _SeatSlot({required this.seat, required this.size});

  final TripSeat? seat;
  final double size;

  @override
  Widget build(BuildContext context) {
    final resolved = seat;
    if (resolved == null) return SizedBox(width: size, height: size);
    return TripSeatTile(seat: resolved, size: size);
  }
}
