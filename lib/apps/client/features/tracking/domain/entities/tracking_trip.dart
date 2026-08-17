import 'package:bmt_app/core/tracking/progress/route_stop.dart';
import 'package:bmt_app/core/tracking/progress/station_board.dart';

import 'tracking_crew.dart';
import 'tracking_point.dart';
import 'tracking_rider.dart';
import 'tracking_trip_state.dart';

export 'tracking_crew.dart';
export 'tracking_point.dart';
export 'tracking_rider.dart';
export 'tracking_trip_state.dart';
export 'vehicle_feed.dart';

/// Everything the tracking screen knows about one trip, all of it read from
/// Supabase. There are no placeholder defaults here on purpose: a field we do
/// not have is null, and the UI is responsible for saying so honestly instead
/// of rendering an invented "Driver assigned" / "Plate pending".
class TrackingTripData {
  const TrackingTripData({
    required this.stops,
    required this.tripState,
    this.stations = const StationBoard.empty(),
    this.tripId,
    this.bookingId,
    this.tripCode,
    this.routeName,
    this.departureAt,
    this.arrivalAt,
    this.arrivalEventCount = 0,
    this.captain = const TrackingCaptain(),
    this.vehicle = const TrackingVehicle(),
    this.rider = const TrackingRider(),
    this.vehicleFix,
    this.hasReview = false,
  });

  /// The empty result: the rider has no trackable booking at all.
  const TrackingTripData.none()
    : stops = const [],
      tripState = TrackingTripState.notStarted,
      stations = const StationBoard.empty(),
      tripId = null,
      bookingId = null,
      tripCode = null,
      routeName = null,
      departureAt = null,
      arrivalAt = null,
      arrivalEventCount = 0,
      captain = const TrackingCaptain(),
      vehicle = const TrackingVehicle(),
      rider = const TrackingRider(),
      vehicleFix = null,
      hasReview = false;

  /// The trip's stops in route order (`trip_route_points.point_order`), each
  /// with its real coordinates and planned times.
  final List<RouteStop> stops;

  /// The live station board: which stops the vehicle has actually reached and
  /// left, and the boarding tally at each.
  ///
  /// Empty until the trip starts boarding — the board is built at that moment,
  /// and before it exists the published schedule in [stops] is the honest answer.
  final StationBoard stations;

  final TrackingTripState tripState;
  final String? tripId;
  final String? bookingId;
  final String? tripCode;
  final String? routeName;
  final DateTime? departureAt;
  final DateTime? arrivalAt;

  /// How many per-station arrivals the captain has confirmed. Seeds the
  /// progress engine as an authoritative floor under GPS inference.
  final int arrivalEventCount;

  final TrackingCaptain captain;
  final TrackingVehicle vehicle;
  final TrackingRider rider;

  /// The captain's latest reported position; null until one arrives.
  final TrackingPoint? vehicleFix;

  /// Whether this booking has already been reviewed, so a completed trip
  /// offers the review flow only when there is still a review to leave.
  final bool hasReview;

  /// No booking to track. Distinct from "a trip whose data has not loaded".
  bool get isEmpty => tripId == null;

  bool get hasLiveVehicleLocation => vehicleFix != null;

  bool get hasRoute => stops.length > 1;

  double? get vehicleSpeedKmh => vehicleFix?.speedKmh;

  /// The stop coordinates the map draws its route line through.
  List<TrackingPoint> get routePoints => stops
      .map((s) => TrackingPoint(latitude: s.latitude, longitude: s.longitude))
      .toList(growable: false);

  String? get originName => stops.isEmpty ? null : stops.first.name;

  String? get destinationName => stops.isEmpty ? null : stops.last.name;

  /// This rider's own stop on the live board, matched by route point id and
  /// falling back to the name — null before the board exists or when the
  /// manifest point does not correspond to any stop on this trip.
  TripStation? get riderStation => stations.stationForPickup(
    routePointId: rider.boardingPointId,
    name: rider.boardingName,
  );

  /// The vehicle is standing at this rider's stop right now, so boarding is a
  /// thing they can actually do. The database checks the same thing before it
  /// accepts a confirmation.
  bool get isVehicleAtRiderStation => riderStation?.isCurrent ?? false;

  TrackingTripData copyWith({
    TrackingTripState? tripState,
    TrackingPoint? vehicleFix,
    bool? hasReview,
  }) {
    return TrackingTripData(
      stops: stops,
      stations: stations,
      tripState: tripState ?? this.tripState,
      tripId: tripId,
      bookingId: bookingId,
      tripCode: tripCode,
      routeName: routeName,
      departureAt: departureAt,
      arrivalAt: arrivalAt,
      arrivalEventCount: arrivalEventCount,
      captain: captain,
      vehicle: vehicle,
      rider: rider,
      vehicleFix: vehicleFix ?? this.vehicleFix,
      hasReview: hasReview ?? this.hasReview,
    );
  }
}
