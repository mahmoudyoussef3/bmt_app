enum TripStatus { upcoming, inProgress, completed, cancelled }

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
