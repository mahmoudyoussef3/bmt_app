import '../../domain/entities/trip_seat.dart';

/// Maps a raw `trip_seats` row into a [TripSeat], flagging the passenger's own
/// seat so Trip Details can render the same live layout seen while booking.
abstract final class TripSeatMapper {
  static TripSeat fromRow(
    Map<String, dynamic> row, {
    required int index,
    required String mySeatLabel,
  }) {
    final label = row['seat_label']?.toString() ?? '';
    final number =
        int.tryParse(label.replaceAll(RegExp(r'[^0-9]'), '')) ?? index + 1;
    final state = row['state']?.toString().toLowerCase() ?? 'reserved';
    final mine = mySeatLabel.trim().toLowerCase();
    final isMine = mine.isNotEmpty && label.trim().toLowerCase() == mine;

    return TripSeat(
      label: label,
      number: number,
      row: (row['seat_row'] as num?)?.toInt() ?? 0,
      column: (row['seat_column'] as num?)?.toInt() ?? 0,
      state: isMine
          ? TripSeatState.mine
          : state == 'available'
          ? TripSeatState.available
          : TripSeatState.occupied,
    );
  }
}
