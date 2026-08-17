import 'package:bmt_app/core/tracking/progress/arrival_events.dart';
import 'package:bmt_app/core/tracking/progress/route_progress_engine.dart';
import 'package:bmt_app/core/tracking/progress/route_progress_snapshot.dart';
import 'package:bmt_app/core/tracking/progress/stop_progress.dart';

import '../../domain/entities/tracking_trip.dart';

/// Owns the route progress engine across a tracking session.
///
/// One engine is kept alive per trip so stop states stay monotonic across
/// silent refreshes — rebuilding it on every refetch would let a stop that had
/// already been passed flicker back to "upcoming".
class TrackingProgressController {
  RouteProgressEngine? _engine;
  String? _tripId;
  int _stopCount = 0;

  /// Rebuilds the engine only when the trip (or its stop list) actually
  /// changes, then folds in the captain's confirmed arrivals and the latest
  /// GPS fix, and returns a fresh snapshot.
  RouteProgressSnapshot? sync(TrackingTripData data, {required DateTime now}) {
    if (data.stops.isEmpty) return null;

    final rebuild =
        _engine == null ||
        _tripId != data.tripId ||
        _stopCount != data.stops.length;

    if (rebuild) {
      _engine = RouteProgressEngine(
        stops: data.stops,
        scheduledDeparture: data.departureAt,
        scheduledArrival: data.arrivalAt,
        phase: phaseFor(data.tripState),
      );
      _tripId = data.tripId;
      _stopCount = data.stops.length;
    } else {
      _engine!.updatePhase(phaseFor(data.tripState));
    }

    final floor = stationArrivalFloor(
      arrivalEventCount: data.arrivalEventCount,
      routePointCount: data.stops.length,
    );
    if (floor > 0) _engine!.seedVisited(floor);

    final fix = data.vehicleFix;
    if (fix != null) {
      _engine!.addFix(
        latitude: fix.latitude,
        longitude: fix.longitude,
        speedKmh: fix.speedKmh,
        now: now,
      );
    }
    return _engine!.snapshot(now);
  }

  /// Folds a single live fix in without a refetch.
  RouteProgressSnapshot? addFix(
    TrackingPoint fix,
    TrackingTripState state, {
    required DateTime now,
  }) {
    final engine = _engine;
    if (engine == null) return null;
    engine.updatePhase(phaseFor(state));
    engine.addFix(
      latitude: fix.latitude,
      longitude: fix.longitude,
      speedKmh: fix.speedKmh,
      now: now,
    );
    return engine.snapshot(now);
  }

  /// ETAs are moments in time, so they go stale on their own; the ticker
  /// re-reads the engine without touching the network.
  RouteProgressSnapshot? tick(DateTime now) => _engine?.snapshot(now);

  static TripProgressPhase phaseFor(TrackingTripState state) =>
      switch (state) {
        TrackingTripState.notStarted ||
        TrackingTripState.driverOnWay => TripProgressPhase.headingToPickup,
        TrackingTripState.boarding => TripProgressPhase.boarding,
        TrackingTripState.inProgress => TripProgressPhase.enRoute,
        TrackingTripState.completed => TripProgressPhase.completed,
      };
}
