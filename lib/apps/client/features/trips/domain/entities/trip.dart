import 'trip_seat.dart';

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

enum PaymentStatus { paid, pending, underReview, refunded, failed }

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
    required this.driverPhone,
    required this.driverInitials,
    required this.driverRating,
    required this.vehicleName,
    required this.vehicleType,
    required this.vehicleId,
    required this.seats,
    required this.paymentStatus,
    required this.fare,
    this.tripId = '',
    this.seatMap = const [],
    this.cancellationReason,
    this.completedAt,
  });

  final String id;

  /// The `operation_trips` id (distinct from the booking [id]) — needed to
  /// resolve the trip's real seat layout.
  final String tripId;

  /// The vehicle's real seat layout for this trip, with the passenger's own
  /// seat flagged. Empty until details are loaded (list cards omit it).
  final List<TripSeat> seatMap;

  final String reference;
  final TripStatus status;
  final String pickup;
  final String destination;
  final String dateLabel;
  final String timeLabel;
  final String driverName;
  final String driverPhone;
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

  bool get hasSeatMap => seatMap.isNotEmpty;

  int get vehicleCapacity => seatMap.length;

  int get availableSeatCount => seatMap.where((seat) => seat.isAvailable).length;

  /// The passenger's own seats — from the live layout when available, else the
  /// booking's seat labels (so the summary never goes blank).
  List<String> get mySeatLabels {
    final fromMap = seatMap
        .where((seat) => seat.isMine)
        .map((seat) => seat.displayLabel)
        .toList();
    if (fromMap.isNotEmpty) return fromMap;
    return seats.where((seat) => seat.trim().isNotEmpty).toList();
  }

  String get paymentLabel {
    return switch (paymentStatus) {
      PaymentStatus.paid => 'Paid',
      PaymentStatus.pending => 'Pending',
      PaymentStatus.underReview => 'Under Review',
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
