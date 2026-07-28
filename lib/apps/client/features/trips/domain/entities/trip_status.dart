/// Where the *journey* is: derived from `operation_trips.status`.
///
/// This is one of three independent axes and answers only "is the vehicle
/// coming, moving, done, or called off". It deliberately says nothing about
/// whether this rider's seat is paid for — see [BookingState] and
/// [PaymentStatus].
enum TripStatus { upcoming, inProgress, completed, cancelled }

/// Where the rider's own *booking* is: derived from `operation_bookings.status`.
///
/// This axis was previously absent from the Client app, which folded it into
/// [TripStatus] and kept only "cancelled". The consequence was measurable: 17 of
/// the 32 bookings in the production database sit at `reserved` / payment
/// `pending`, and every one of them rendered as a plain "Upcoming" trip — no
/// hint that the seat is only *held*, that the hold expires, or that a human
/// still has to approve the payment.
enum BookingState {
  /// The seat is held and the payment is waiting on the operator. The rider
  /// still has something to do or wait for; the seat is not theirs yet.
  reserved,

  /// Payment approved, seat is the rider's.
  confirmed,

  /// The journey happened.
  completed,

  /// The booking is off — by the rider, the operator, or a rejected payment.
  cancelled,
}

enum TripFilter { upcoming, active, completed, cancelled }

extension TripFilterLabel on TripFilter {
  TripStatus get statusMatch {
    return switch (this) {
      TripFilter.upcoming => TripStatus.upcoming,
      TripFilter.active => TripStatus.inProgress,
      TripFilter.completed => TripStatus.completed,
      TripFilter.cancelled => TripStatus.cancelled,
    };
  }
}

enum PaymentStatus { paid, pending, underReview, refunded, failed, cancelled }
