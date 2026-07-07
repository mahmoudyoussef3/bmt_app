import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/features/trips/domain/entities/trip_seat.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_seat_tile.dart';

/// Arranges real [TripSeat]s into a believable bus cabin — rows split by a
/// centre aisle — from the live `trip_seats` layout. Falls back to fixed rows
/// of four when the backend hasn't stored row/column coordinates yet.
class TripSeatMap extends StatelessWidget {
  const TripSeatMap({
    super.key,
    required this.seats,
    this.seatSize = 44,
    this.rowSpacing = 10,
    this.seatSpacing = 8,
    this.aisleWidth = 26,
  });

  final List<TripSeat> seats;
  final double seatSize;
  final double rowSpacing;
  final double seatSpacing;
  final double aisleWidth;

  @override
  Widget build(BuildContext context) {
    final rows = _rows();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) SizedBox(height: rowSpacing),
          _SeatRow(
            seats: rows[i],
            seatSize: seatSize,
            seatSpacing: seatSpacing,
            aisleWidth: aisleWidth,
          ),
        ],
      ],
    );
  }

  List<List<TripSeat>> _rows() {
    final hasCoordinates = seats.any((seat) => seat.row > 0);
    if (hasCoordinates) {
      final grouped = <int, List<TripSeat>>{};
      for (final seat in seats) {
        grouped.putIfAbsent(seat.row, () => []).add(seat);
      }
      final orderedRows = grouped.keys.toList()..sort();
      return [
        for (final key in orderedRows)
          grouped[key]!..sort((a, b) => a.column.compareTo(b.column)),
      ];
    }

    const perRow = 4;
    return [
      for (var i = 0; i < seats.length; i += perRow)
        seats.sublist(i, math.min(i + perRow, seats.length)),
    ];
  }
}

class _SeatRow extends StatelessWidget {
  const _SeatRow({
    required this.seats,
    required this.seatSize,
    required this.seatSpacing,
    required this.aisleWidth,
  });

  final List<TripSeat> seats;
  final double seatSize;
  final double seatSpacing;
  final double aisleWidth;

  @override
  Widget build(BuildContext context) {
    final mid = (seats.length / 2).ceil();
    final left = seats.sublist(0, mid);
    final right = seats.sublist(mid);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ..._tiles(left),
        SizedBox(width: aisleWidth),
        ..._tiles(right),
      ],
    );
  }

  List<Widget> _tiles(List<TripSeat> group) {
    final widgets = <Widget>[];
    for (var i = 0; i < group.length; i++) {
      if (i > 0) widgets.add(SizedBox(width: seatSpacing));
      widgets.add(TripSeatTile(seat: group[i], size: seatSize));
    }
    return widgets;
  }
}
