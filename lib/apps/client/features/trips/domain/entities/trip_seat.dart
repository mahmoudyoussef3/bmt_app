/// A single physical seat on the trip's vehicle, sourced from the real
/// `trip_seats` table (the same source the booking seat simulation reads).
///
/// [mine] is the passenger's own booked seat, [occupied] is reserved/booked by
/// someone else, and [available] is still free — so Trip Details can render the
/// exact same live layout the passenger saw while booking.
enum TripSeatState { available, occupied, mine }

class TripSeat {
  const TripSeat({
    required this.label,
    required this.number,
    required this.row,
    required this.column,
    required this.state,
  });

  final String label;
  final int number;
  final int row;
  final int column;
  final TripSeatState state;

  bool get isMine => state == TripSeatState.mine;
  bool get isAvailable => state == TripSeatState.available;
  bool get isOccupied => state == TripSeatState.occupied;

  /// What the seat shows to the passenger — its label, falling back to number.
  String get displayLabel => label.trim().isEmpty ? '$number' : label.trim();
}
