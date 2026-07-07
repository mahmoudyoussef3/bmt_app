import 'stop_progress.dart';

/// Render-ready description of how far a trip has progressed along its
/// route, produced by `RouteProgressEngine.snapshot`.
class RouteProgressSnapshot {
  const RouteProgressSnapshot({
    required this.phase,
    required this.hasVehicleFix,
    required this.isStale,
    required this.isOffRoute,
    required this.routeFraction,
    required this.traveledMeters,
    required this.totalRouteMeters,
    required this.stops,
    required this.nextStopIndex,
  });

  factory RouteProgressSnapshot.empty(TripProgressPhase phase) =>
      RouteProgressSnapshot(
        phase: phase,
        hasVehicleFix: false,
        isStale: false,
        isOffRoute: false,
        routeFraction: phase == TripProgressPhase.completed ? 1 : 0,
        traveledMeters: 0,
        totalRouteMeters: 0,
        stops: const [],
        nextStopIndex: null,
      );

  final TripProgressPhase phase;

  /// False until the captain has sent any usable position.
  final bool hasVehicleFix;

  /// True when the last fix is older than the configured stale window.
  final bool isStale;

  /// True when the vehicle is farther from the route than the off-route
  /// threshold; progress freezes while set.
  final bool isOffRoute;

  /// Fraction of the route covered, 0..1.
  final double routeFraction;

  final double traveledMeters;
  final double totalRouteMeters;

  /// Per-stop progress, in route order.
  final List<StopProgress> stops;

  /// Index into [stops] of the stop the vehicle is heading to; null when the
  /// trip is completed or there are no stops.
  final int? nextStopIndex;

  double get remainingMeters =>
      (totalRouteMeters - traveledMeters).clamp(0, totalRouteMeters).toDouble();

  StopProgress? get nextStop => nextStopIndex == null
      ? null
      : stops[nextStopIndex!];

  StopProgress? get destination => stops.isEmpty ? null : stops.last;

  DateTime? get etaToDestination => destination?.eta;

  /// Stops the vehicle has not yet reached (excludes the one it is at).
  int get remainingStopCount => stops
      .where(
        (s) =>
            s.status == StopVisitStatus.upcoming ||
            s.status == StopVisitStatus.next,
      )
      .length;

  /// Finds a stop's progress by (case-insensitive, trimmed) name — how
  /// passenger pickup points reference route stops.
  StopProgress? stopByName(String? name) {
    if (name == null || name.trim().isEmpty) return null;
    final needle = name.trim().toLowerCase();
    for (final stop in stops) {
      if (stop.stop.name.trim().toLowerCase() == needle) return stop;
    }
    return null;
  }
}
