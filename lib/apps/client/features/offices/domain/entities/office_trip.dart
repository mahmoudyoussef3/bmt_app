/// One bookable departure an office is selling right now.
///
/// The profile is a shop window, so this carries what a rider decides on —
/// when it leaves, where it runs, what a seat costs, how many are left — and
/// nothing operational. Only departures the booking RPC will accept ever reach
/// this type; see `BookableTrip`.
class OfficeTrip {
  const OfficeTrip({
    required this.id,
    required this.routeId,
    required this.routeName,
    required this.pickup,
    required this.destination,
    required this.tripDate,
    required this.departureTime,
    required this.duration,
    required this.price,
    required this.seatsLeft,
  });

  final String id;
  final String routeId;
  final String routeName;
  final String pickup;
  final String destination;

  /// ISO `yyyy-MM-dd`; empty when the trip carries no date.
  final String tripDate;

  /// Raw `HH:mm:ss` from Supabase; empty when the trip has no time set.
  final String departureTime;

  final String duration;

  /// Preformatted fare (e.g. `EGP 100`); empty when no fare is published.
  final String price;

  final int seatsLeft;

  bool get isSoldOut => seatsLeft <= 0;
  bool get hasScarceSeats => seatsLeft > 0 && seatsLeft <= 5;
}
