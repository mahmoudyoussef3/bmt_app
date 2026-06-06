enum TripStatus { upcoming, inProgress, completed, cancelled }

enum TripFilter { upcoming, active, completed, cancelled }

extension TripFilterLabel on TripFilter {
  String get label {
    return switch (this) {
      TripFilter.upcoming => 'Upcoming',
      TripFilter.active => 'Active',
      TripFilter.completed => 'Completed',
      TripFilter.cancelled => 'Cancelled',
    };
  }

  TripStatus get statusMatch {
    return switch (this) {
      TripFilter.upcoming => TripStatus.upcoming,
      TripFilter.active => TripStatus.inProgress,
      TripFilter.completed => TripStatus.completed,
      TripFilter.cancelled => TripStatus.cancelled,
    };
  }
}

enum PaymentStatus { paid, pending, refunded, failed }

class TripData {
  const TripData({
    required this.id,
    required this.reference,
    required this.status,
    required this.pickup,
    required this.destination,
    required this.dateLabel,
    required this.timeLabel,
    required this.driverName,
    required this.driverInitials,
    required this.driverRating,
    required this.vehicleName,
    required this.vehicleType,
    required this.vehicleId,
    required this.seats,
    required this.paymentStatus,
    required this.fare,
    this.cancellationReason,
    this.completedAt,
  });

  final String id;
  final String reference;
  final TripStatus status;
  final String pickup;
  final String destination;
  final String dateLabel;
  final String timeLabel;
  final String driverName;
  final String driverInitials;
  final double driverRating;
  final String vehicleName;
  final String vehicleType;
  final String vehicleId;
  final List<String> seats;
  final PaymentStatus paymentStatus;
  final String fare;
  final String? cancellationReason;
  final String? completedAt;

  String get routeLine => '$pickup → $destination';

  String get paymentLabel {
    return switch (paymentStatus) {
      PaymentStatus.paid => 'Paid',
      PaymentStatus.pending => 'Pending',
      PaymentStatus.refunded => 'Refunded',
      PaymentStatus.failed => 'Failed',
    };
  }

  String get statusLabel {
    return switch (status) {
      TripStatus.upcoming => 'Upcoming',
      TripStatus.inProgress => 'In progress',
      TripStatus.completed => 'Completed',
      TripStatus.cancelled => 'Cancelled',
    };
  }
}
