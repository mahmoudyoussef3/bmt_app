import 'package:bmt_app/apps/captain/core/trips/captain_trip_stage.dart';

enum AssignedTripStatus {
  scheduled,
  openForBooking,
  boarding,
  inProgress,
  completed,
}

extension AssignedTripStatusX on AssignedTripStatus {
  bool get isRunning =>
      this == AssignedTripStatus.boarding ||
      this == AssignedTripStatus.inProgress;

  bool get isUpcoming =>
      this == AssignedTripStatus.scheduled ||
      this == AssignedTripStatus.openForBooking;
}

class AssignedTripStop {
  const AssignedTripStop({
    required this.id,
    required this.name,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String name;

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

  final int arrivedStationsCount;

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
