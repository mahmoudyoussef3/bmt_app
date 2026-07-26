import 'package:bmt_app/apps/captain/features/passenger_manifest/domain/entities/passenger.dart';

/// One rider waiting to board at a pickup stop, projected from the manifest.
class PickupRider {
  const PickupRider({
    required this.tripPassengerId,
    required this.name,
    required this.seat,
    required this.phone,
    required this.status,
  });

  final String tripPassengerId;
  final String name;
  final String seat;
  final String phone;
  final PassengerBoardingStatus status;

  bool get isPending => status == PassengerBoardingStatus.pending;
  bool get hasBoarded => status == PassengerBoardingStatus.boarded;
  bool get isAbsent => status == PassengerBoardingStatus.absent;

  /// The captain has dealt with this rider one way or the other — they are on
  /// board or they were marked a no-show. Either way the pickup can move on.
  bool get isResolved => !isPending;
}

/// A stop on the route where at least one rider boards, with the riders grouped
/// under it. This is what "next pickup" is in a fixed-route service: not a
/// per-rider GPS point, but the next scheduled stop that still has someone
/// waiting.
class PickupStop {
  const PickupStop({
    required this.name,
    required this.riders,
    this.stopIndex,
    this.stopId,
    this.latitude,
    this.longitude,
  });

  /// The stop's display name (the route point's name when matched, else the
  /// pickup name the booking carried).
  final String name;

  final List<PickupRider> riders;

  /// Index into the trip's ordered route stops, or null when the booking's
  /// pickup name matched no route point (older bookings, renamed stops).
  final int? stopIndex;

  /// The `trip_route_points` row id, for reporting an arrival against it.
  final String? stopId;

  final double? latitude;
  final double? longitude;

  bool get hasCoordinates => latitude != null && longitude != null;

  int get pendingCount => riders.where((r) => r.isPending).length;
  int get boardedCount => riders.where((r) => r.hasBoarded).length;
  int get absentCount => riders.where((r) => r.isAbsent).length;
  int get total => riders.length;

  /// Every rider here has boarded or been marked absent — nothing left to do.
  bool get isResolved => riders.every((r) => r.isResolved);
}

/// The full pickup sequence for a trip, in route order, plus which stop is the
/// one the captain is working right now.
///
/// The active stop is derived purely from rider status: it is the first stop
/// (in order) that still has a pending rider. Confirming the last pending rider
/// at a stop makes the *next* stop active with no manual selection — the
/// automatic promotion the flow asks for is just re-running this derivation.
class PickupPlan {
  const PickupPlan({required this.stops, required this.activeIndex});

  const PickupPlan.empty() : stops = const [], activeIndex = null;

  /// Pickup stops in route order; only stops that actually have riders boarding.
  final List<PickupStop> stops;

  /// Index into [stops] of the active pickup, or null when every rider has been
  /// resolved (all boarded or absent).
  final int? activeIndex;

  PickupStop? get active =>
      activeIndex == null ? null : stops[activeIndex!];

  /// The stop after the active one, so the captain can see who is coming up.
  PickupStop? get upcoming {
    final index = activeIndex;
    if (index == null || index + 1 >= stops.length) return null;
    return stops[index + 1];
  }

  bool get isEmpty => stops.isEmpty;

  /// A trip with riders, all of whom have been dealt with.
  bool get isAllResolved => stops.isNotEmpty && activeIndex == null;

  int get totalRiders =>
      stops.fold(0, (sum, stop) => sum + stop.total);

  int get totalBoarded =>
      stops.fold(0, (sum, stop) => sum + stop.boardedCount);

  int get totalPending =>
      stops.fold(0, (sum, stop) => sum + stop.pendingCount);
}
