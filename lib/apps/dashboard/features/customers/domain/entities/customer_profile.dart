import 'customer_subscription.dart';

/// Identity, exactly as `clients` holds it.
class CustomerIdentity {
  final String clientId;
  final String fullName;
  final String phone;
  final String? email;
  final String status;
  final DateTime joinedAt;

  const CustomerIdentity({
    required this.clientId,
    required this.fullName,
    required this.phone,
    required this.status,
    required this.joinedAt,
    this.email,
  });

  String get initials {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '؟';
    String head(String s, int n) => String.fromCharCodes(s.runes.take(n));
    if (parts.length == 1) return head(parts.first, 2);
    return '${head(parts[0], 1)}${head(parts[1], 1)}';
  }

  /// The short form of the id, for the operator to read back over the phone.
  /// The full uuid is never shown — eight characters identify a row inside one
  /// office and are the most anyone can repeat aloud without a mistake.
  String get shortId =>
      clientId.length >= 8 ? clientId.substring(0, 8).toUpperCase() : clientId;
}

/// Everything the office can count about this passenger, all of it office-scoped.
class CustomerMetrics {
  final int bookingsTotal;
  final int bookingsUpcoming;
  final int bookingsCompleted;
  final int bookingsCancelled;
  final DateTime? firstBookingAt;
  final DateTime? lastBookingAt;
  final DateTime? nextTripDate;

  /// Manifest facts, from `trip_passengers` on this office's trips.
  final int boardedCount;
  final int noShowCount;

  final double totalPaid;
  final int paymentsCount;
  final DateTime? lastPaymentAt;

  final int subscriptionsTotal;
  final int activeSubscriptions;

  /// Null when the office has never opened a wallet for this customer, which is
  /// a different statement from a zero balance.
  final double? walletBalance;
  final String? walletStatus;
  final String? walletCurrency;
  final DateTime? lastWalletAt;

  final int reviewsCount;

  /// Mean of `trip_reviews.office_rating` — this office's own rating from this
  /// customer, not the driver's or the vehicle's.
  final double? avgOfficeRating;

  final int ticketsTotal;
  final int ticketsOpen;

  final double refundsSettledAmount;

  const CustomerMetrics({
    this.bookingsTotal = 0,
    this.bookingsUpcoming = 0,
    this.bookingsCompleted = 0,
    this.bookingsCancelled = 0,
    this.firstBookingAt,
    this.lastBookingAt,
    this.nextTripDate,
    this.boardedCount = 0,
    this.noShowCount = 0,
    this.totalPaid = 0,
    this.paymentsCount = 0,
    this.lastPaymentAt,
    this.subscriptionsTotal = 0,
    this.activeSubscriptions = 0,
    this.walletBalance,
    this.walletStatus,
    this.walletCurrency,
    this.lastWalletAt,
    this.reviewsCount = 0,
    this.avgOfficeRating,
    this.ticketsTotal = 0,
    this.ticketsOpen = 0,
    this.refundsSettledAmount = 0,
  });

  /// The newest thing that happened, across the three streams the office owns.
  DateTime? get lastActivityAt {
    final candidates = [
      lastBookingAt,
      lastPaymentAt,
      lastWalletAt,
    ].whereType<DateTime>().toList();
    if (candidates.isEmpty) return null;
    candidates.sort();
    return candidates.last;
  }

  /// Share of this customer's bookings they called off.
  ///
  /// Null below four bookings: one cancellation out of two is 50%, and printing
  /// that beside a customer who has travelled twice would be a slander dressed
  /// as a statistic.
  double? get cancellationRate {
    if (bookingsTotal < 4) return null;
    return bookingsCancelled / bookingsTotal;
  }

  /// Manifest rows where the passenger was marked aboard, over rows that
  /// reached a verdict. Null while none has — a manifest that is still
  /// `reserved` has not yet said anything about attendance.
  double? get boardingRate {
    final decided = boardedCount + noShowCount;
    if (decided == 0) return null;
    return boardedCount / decided;
  }
}

/// A route this customer books, and how often. Derived from their own bookings.
class CustomerRoute {
  final String route;
  final int trips;

  const CustomerRoute({required this.route, required this.trips});
}

/// The Customer 360 header and نظرة عامة, in one round trip.
class CustomerProfile {
  final CustomerIdentity client;
  final CustomerMetrics metrics;

  /// The subscription in force today, if any. Distinct from the الاشتراكات tab,
  /// which lists every subscription ever sold to this customer.
  final CustomerSubscription? activeSubscription;

  final List<CustomerRoute> topRoutes;

  const CustomerProfile({
    required this.client,
    required this.metrics,
    this.activeSubscription,
    this.topRoutes = const [],
  });
}
