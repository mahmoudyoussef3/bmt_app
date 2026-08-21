/// One booking of this customer's, with the trip and manifest context joined on.
///
/// Three status axes travel together and mean different things. Collapsing them
/// into one badge is the mistake this class exists to prevent:
///
///   [status]         what the *booking* is — reserved, confirmed, cancelled…
///   [paymentStatus]  what the *money* did — submitted, approved, refunded…
///   [boardingStatus] what the *passenger* did — reserved, completed, no_show
///
/// A confirmed booking with an approved payment and a `no_show` manifest row is
/// a coherent, common record: they paid and did not turn up.
class CustomerTrip {
  final String bookingId;
  final String? bookingNumber;
  final String route;
  final DateTime? tripDate;
  final String? tripTime;
  final String? seat;
  final String? pickupPointName;
  final String? dropoffPointName;

  /// `operation_bookings.status`.
  final String status;

  /// `operation_bookings.payment_status`.
  final String? paymentStatus;
  final double paymentAmount;
  final String? paymentMethod;

  final DateTime? cancelledAt;
  final String? cancellationReason;
  final DateTime createdAt;

  /// True when the booking consumed a package ride.
  final bool viaSubscription;
  final bool viaPackage;

  /// The package's Arabic name, resolved through `transport_subscriptions`.
  final String? subscriptionName;

  /// `operation_trips.status` — the trip's own state, which can differ from the
  /// booking's (a scheduled trip full of confirmed bookings).
  final String? tripStatus;
  final String? tripCode;

  /// `trip_passengers.status`, null when the passenger was never placed on a
  /// manifest.
  final String? boardingStatus;
  final DateTime? boardedAt;
  final String? noShowReason;

  const CustomerTrip({
    required this.bookingId,
    required this.route,
    required this.status,
    required this.createdAt,
    this.bookingNumber,
    this.tripDate,
    this.tripTime,
    this.seat,
    this.pickupPointName,
    this.dropoffPointName,
    this.paymentStatus,
    this.paymentAmount = 0,
    this.paymentMethod,
    this.cancelledAt,
    this.cancellationReason,
    this.viaSubscription = false,
    this.viaPackage = false,
    this.subscriptionName,
    this.tripStatus,
    this.tripCode,
    this.boardingStatus,
    this.boardedAt,
    this.noShowReason,
  });

  bool get wasBoarded => boardedAt != null;

  bool get wasNoShow => boardingStatus == 'no_show';

  bool get isCancelled => status == 'cancelled';
}

/// A page of القادمة or السابقة.
class CustomerTripsPage {
  final int total;
  final List<CustomerTrip> rows;

  const CustomerTripsPage({required this.total, required this.rows});

  const CustomerTripsPage.empty() : total = 0, rows = const [];
}
