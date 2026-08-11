import 'package:bmt_app/core/tracking/progress/route_progress_snapshot.dart';
import 'package:bmt_app/core/tracking/progress/stop_progress.dart';

import '../../domain/entities/tracking_trip.dart';

/// The one stop the rider is actually waiting on.
///
/// A trip has many stops, but at any moment a rider cares about exactly one:
/// before they board it is *their* boarding point ("when does it reach me?"),
/// and once they are on board it is *their* drop-off ("when do I get there?").
/// The old screen counted down to the route's final stop regardless, which is
/// the wrong number for every passenger who doesn't ride to the end of the line.
class TrackingFocus {
  const TrackingFocus({required this.target, required this.isBoarding});

  /// Null when the trip has no progress data yet, or the rider's stops could
  /// not be matched — the UI falls back to the scheduled times.
  final StopProgress? target;

  /// True while the countdown is to the rider's boarding point rather than to
  /// where they get off. Drives which label the hero ETA carries.
  final bool isBoarding;

  bool get hasTarget => target != null;

  DateTime? get eta => target?.eta;

  EtaConfidence get confidence =>
      target?.etaConfidence ?? EtaConfidence.none;

  static TrackingFocus of(
    TrackingTripData trip,
    RouteProgressSnapshot? progress,
  ) {
    final stops = progress?.stops ?? const <StopProgress>[];
    if (stops.isEmpty) return const TrackingFocus(target: null, isBoarding: false);

    final rider = trip.rider;

    if (!rider.hasBoarded) {
      final boarding = _stopAt(stops, rider.boardingIndex);
      if (boarding != null && !boarding.isVisited) {
        return TrackingFocus(target: boarding, isBoarding: true);
      }
    }

    final dropoff = _stopAt(stops, rider.dropoffIndex);
    return TrackingFocus(
      target: dropoff ?? stops.last,
      isBoarding: false,
    );
  }

  static StopProgress? _stopAt(List<StopProgress> stops, int? index) {
    if (index == null || index < 0 || index >= stops.length) return null;
    return stops[index];
  }
}
