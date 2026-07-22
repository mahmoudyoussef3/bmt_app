/// The one definition of "a rider can take a seat on this" in the Client app.
///
/// `public_trips` deliberately exposes five statuses — `open_for_booking`,
/// `scheduled`, `boarding`, `in_progress`, `completed` — because a rider must
/// still be able to read a trip they already booked while it runs and after it
/// ends. Only the first of those can be *sold*: `confirm_seat_booking_v2`
/// rejects anything else with `trip_not_available`. Every discovery surface
/// therefore filters through here, so a rider is never offered a departure the
/// server will refuse.
abstract final class BookableTrip {
  const BookableTrip._();

  /// The only `operation_trips.status` the booking RPC accepts.
  static const String status = 'open_for_booking';

  /// Today as `yyyy-MM-dd`, the form `trip_date` is stored and compared in.
  static String today() => DateTime.now().toIso8601String().split('T').first;

  /// The Postgrest embed every caller must select for [seatsLeft] to be real.
  static const String seatsEmbed = 'trip_seats(state)';

  /// Seats still free on a trip row.
  ///
  /// `trip_seats.state` is the truth: the booking RPC moves seats through
  /// `available → reserved → paid` and never touches the denormalised
  /// `booked_seats` counter, which has read 0 since the flow was rewritten.
  /// The counter is kept only as a fallback for a row fetched without
  /// [seatsEmbed].
  static int seatsLeft(Map<String, dynamic> trip) {
    final seats = trip['trip_seats'];
    if (seats is List) {
      return seats
          .whereType<Map>()
          .where((seat) => seat['state']?.toString() == 'available')
          .length;
    }
    final capacity = (trip['capacity'] as num?)?.toInt() ?? 0;
    final used = (trip['booked_seats'] as num?)?.toInt() ?? 0;
    return (capacity - used).clamp(0, capacity);
  }

  /// Whether the departure has not already sailed. A row without a date is
  /// treated as upcoming — the dashboard, not the rider, owns that gap.
  static bool isUpcoming(Map<String, dynamic> trip) {
    final tripDate = trip['trip_date']?.toString();
    if (tripDate == null || tripDate.isEmpty) return true;
    return tripDate.compareTo(today()) >= 0;
  }

  /// Whether this row may be offered for booking at all — status and date
  /// only. Seat availability is deliberately *not* part of this: a sold-out
  /// departure is still worth showing, with its CTA disabled, so a rider sees
  /// that the bus exists and fills up.
  static bool isOffered(Map<String, dynamic> trip) =>
      trip['status']?.toString() == status && isUpcoming(trip);

  /// Whether a seat can actually be taken on this row right now.
  static bool isBookable(Map<String, dynamic> trip) =>
      isOffered(trip) && seatsLeft(trip) > 0;
}
