/// The minimum a trip must be for a passenger to review it.
///
/// The review flow is reached from two places — trip details and live tracking
/// — which know very different things about a trip. Rather than force either
/// caller to fabricate the fields it doesn't have (a seat map, a fare, a
/// payment status) just to open a review sheet, both hand over this: the
/// booking to review, whether it is actually finished, and the handful of
/// labels the sheet displays back to the passenger.
class ReviewableTrip {
  const ReviewableTrip({
    required this.bookingId,
    required this.isCompleted,
    required this.reference,
    this.officeName = '',
    this.driverName = '',
    this.vehicleName = '',
    this.origin = '',
    this.destination = '',
    this.routeName = '',
  });

  /// `operation_bookings.id` — the review is keyed on the booking, because
  /// that is what identifies *this passenger's* ride on a shared trip.
  final String bookingId;

  /// Only a trip that actually ran can be reviewed. The `submit_trip_review`
  /// RPC enforces this too; checking here just means the passenger is told
  /// immediately instead of after a round trip.
  final bool isCompleted;

  final String reference;

  /// Labels the sheet echoes back to the passenger. Empty when the caller
  /// genuinely doesn't know — the sheet omits the line rather than filling it.
  final String officeName;
  final String driverName;
  final String vehicleName;

  /// The two ends of the ride, kept apart rather than joined into one string.
  /// Which way round they read on screen depends on the ambient text direction
  /// and on the script of the names themselves, so only the presentation layer
  /// can compose them — see `routeDirectionLabel`.
  final String origin;
  final String destination;

  /// The route's own name, shown when the endpoints aren't known.
  final String routeName;

  bool get hasEndpoints => origin.isNotEmpty && destination.isNotEmpty;
}
