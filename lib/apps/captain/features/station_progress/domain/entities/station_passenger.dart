/// A rider due to board at one station, as the captain sees them.
///
/// Deliberately narrower than the manifest's [Passenger]: this list exists only
/// to answer "who is holding the vehicle here, and how do I resolve them?", so
/// it carries the seat and the phone the captain would call, and nothing else.
class StationPassenger {
  const StationPassenger({
    required this.id,
    required this.name,
    required this.seatLabel,
    required this.phone,
    required this.status,
  });

  final String id;
  final String name;
  final String seatLabel;
  final String phone;
  final StationPassengerStatus status;

  bool get isPending => status == StationPassengerStatus.pending;
}

/// `trip_passengers.status`, narrowed to the values a station cares about.
/// `confirmed` is the manifest's word for "physically aboard".
enum StationPassengerStatus { pending, boarded, noShow, cancelled }

StationPassengerStatus stationPassengerStatusFrom(String? raw) => switch (raw) {
  'confirmed' || 'completed' => StationPassengerStatus.boarded,
  'no_show' => StationPassengerStatus.noShow,
  'cancelled' => StationPassengerStatus.cancelled,
  _ => StationPassengerStatus.pending,
};

/// Why a rider who was expected is not travelling.
///
/// There is no "skip" here on purpose: every value is a statement about the
/// passenger that the captain is putting their name to, and the database
/// refuses `other` without an accompanying note.
enum NoShowReason {
  didNotArrive,
  cancelledByPassenger,
  passengerRequested,
  other,
}

extension NoShowReasonX on NoShowReason {
  /// The wire value `captain_resolve_no_show` validates against.
  String get wireValue => switch (this) {
    NoShowReason.didNotArrive => 'did_not_arrive',
    NoShowReason.cancelledByPassenger => 'cancelled_by_passenger',
    NoShowReason.passengerRequested => 'passenger_requested',
    NoShowReason.other => 'other',
  };

  bool get requiresNote => this == NoShowReason.other;
}
