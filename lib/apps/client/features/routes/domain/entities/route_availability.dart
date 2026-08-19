/// Whether a corridor can actually be booked, as the catalog states it before
/// the rider taps in.
///
/// Four states rather than a yes/no, because "the bus is full" and "no bus is
/// running" are different facts and only one of them is worth waiting for.
enum RouteAvailabilityStatus {
  /// Not established. The catalog loaded but its departures could not be read,
  /// so the card says nothing rather than guessing — a wrong "unavailable"
  /// costs the office a sale, and a wrong "available" costs the rider a trip.
  unknown,

  /// At least one upcoming departure is on sale with a seat still free.
  bookable,

  /// Departures exist but every seat on them is taken.
  soldOut,

  /// Nothing on this corridor is on sale for today or later.
  none,
}

/// The booking outlook for one route in the catalog.
///
/// Derived from the same `public_trips` rows the booking flow sells from, and
/// through the same [BookableTrip] predicates, so the badge on a card can never
/// promise a departure the booking RPC would refuse.
class RouteAvailability {
  const RouteAvailability({
    required this.status,
    this.nextDepartureDate = '',
    this.nextDepartureTime = '',
    this.seatsLeft = 0,
    this.tripCount = 0,
  });

  /// The catalog could not read departures at all.
  static const RouteAvailability unknown = RouteAvailability(
    status: RouteAvailabilityStatus.unknown,
  );

  /// Read successfully, and there is nothing on sale.
  static const RouteAvailability none = RouteAvailability(
    status: RouteAvailabilityStatus.none,
  );

  final RouteAvailabilityStatus status;

  /// `yyyy-MM-dd` of the soonest departure worth naming: the first bookable
  /// one, or — when the corridor is sold out — the first one on sale, so the
  /// rider learns when the buses actually run. Empty when nothing is on sale.
  final String nextDepartureDate;

  /// `HH:mm:ss` of that same departure. Empty when the office left the trip's
  /// time unset.
  final String nextDepartureTime;

  /// Seats still free on that departure. Zero unless [isBookable].
  final int seatsLeft;

  /// How many upcoming departures still have a seat. Zero unless [isBookable].
  final int tripCount;

  /// Whether the card has anything honest to show. An [unknown] outlook renders
  /// no badge at all.
  bool get isKnown => status != RouteAvailabilityStatus.unknown;

  bool get isBookable => status == RouteAvailabilityStatus.bookable;
}
