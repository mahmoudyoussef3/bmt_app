import 'package:bmt_app/apps/captain/core/trips/captain_trip_stage.dart';

/// Mirrors `operation_trips.status` for the states a captain can see.
///
/// [scheduled] and [openForBooking] are deliberately distinct: the first is an
/// internal ops draft the captain can only wait on, the second is a published
/// trip clients are booking. See [CaptainTripStage].
enum AssignedTripStatus {
  scheduled,
  openForBooking,
  boarding,
  inProgress,
  completed,
}

extension AssignedTripStatusX on AssignedTripStatus {
  /// The captain is on this trip right now: passengers are boarding, or it has
  /// already departed. Either way there is something to drive.
  bool get isRunning =>
      this == AssignedTripStatus.boarding ||
      this == AssignedTripStatus.inProgress;

  /// Still ahead of the captain — assigned or published, but not yet started.
  bool get isUpcoming =>
      this == AssignedTripStatus.scheduled ||
      this == AssignedTripStatus.openForBooking;
}

/// A route station as scheduled for one trip, carrying the `trip_route_points`
/// row id so the captain app can report an arrival against the exact point
/// (see `trip_events` title `'وصول محطة'` convention).
class AssignedTripStop {
  const AssignedTripStop({
    required this.id,
    required this.name,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String name;

  /// Null when the route point was saved without coordinates — captains
  /// created before route mapping was mandatory can still have these.
  final double? latitude;
  final double? longitude;

  bool get hasCoordinates => latitude != null && longitude != null;
}

class AssignedTrip {
  const AssignedTrip({
    required this.id,
    required this.route,
    required this.vehicleNumber,
    required this.plateNumber,
    required this.departureTime,
    required this.expectedArrivalTime,
    required this.stops,
    required this.passengerCount,
    required this.boardedCount,
    this.status = AssignedTripStatus.scheduled,
    this.arrivedStationsCount = 0,
  });

  final String id;
  final String route;
  final String vehicleNumber;
  final String plateNumber;
  final DateTime departureTime;
  final DateTime expectedArrivalTime;
  final List<AssignedTripStop> stops;
  final int passengerCount;
  final int boardedCount;
  final AssignedTripStatus status;

  /// How many leading stations the captain has already reported arrived
  /// (the shared `trip_events` arrival floor, clamped to `stops.length`).
  /// Lets the trip execution screen resume at the right next station
  /// instead of resetting to the first one on every reopen.
  final int arrivedStationsCount;

  /// Where this trip stands for the captain at [now] — the one place the
  /// backend status and the departure clock are combined into a single
  /// answer, so the home card and the execution screen can never disagree
  /// about what the captain is allowed to do next.
  CaptainTripStage stageAt(DateTime now) {
    return switch (status) {
      AssignedTripStatus.completed => CaptainTripStage.finished,
      AssignedTripStatus.inProgress => CaptainTripStage.underway,
      AssignedTripStatus.boarding => CaptainTripStage.boarding,
      AssignedTripStatus.scheduled => CaptainTripStage.awaitingRelease,
      AssignedTripStatus.openForBooking => resolvePublishedStage(
        departureTime: departureTime,
        now: now,
      ),
    };
  }

  AssignedTrip copyWith({AssignedTripStatus? status, int? boardedCount}) {
    return AssignedTrip(
      id: id,
      route: route,
      vehicleNumber: vehicleNumber,
      plateNumber: plateNumber,
      departureTime: departureTime,
      expectedArrivalTime: expectedArrivalTime,
      stops: stops,
      passengerCount: passengerCount,
      boardedCount: boardedCount ?? this.boardedCount,
      status: status ?? this.status,
      arrivedStationsCount: arrivedStationsCount,
    );
  }
}
