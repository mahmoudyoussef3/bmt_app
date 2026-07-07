import 'route_stop.dart';

/// Where the trip is in its lifecycle, from the progress engine's point of
/// view. Apps map their own status vocabularies onto these phases.
enum TripProgressPhase { headingToPickup, boarding, enRoute, completed }

/// Visit state of a single stop. `next` is derived (the first unvisited
/// stop); `arrived` means the vehicle is at the stop right now.
enum StopVisitStatus { upcoming, next, arrived, departed }

/// How trustworthy an ETA is.
///
/// `live` — fresh GPS and the vehicle is moving; `estimated` — fresh GPS but
/// dwelling/slow, so pace is inferred; `scheduled` — no usable GPS, the
/// published plan is all we have; `none` — nothing to estimate from.
enum EtaConfidence { live, estimated, scheduled, none }

/// Progress of one stop: its visit state plus the distance and ETA to it.
class StopProgress {
  const StopProgress({
    required this.stop,
    required this.status,
    this.remainingMeters,
    this.eta,
    this.etaConfidence = EtaConfidence.none,
  });

  final RouteStop stop;
  final StopVisitStatus status;

  /// Along-route distance left to this stop; null once visited or unknown.
  final double? remainingMeters;

  /// Estimated arrival time; null once visited or when nothing can be
  /// estimated.
  final DateTime? eta;
  final EtaConfidence etaConfidence;

  bool get isVisited =>
      status == StopVisitStatus.departed || status == StopVisitStatus.arrived;
}
