import 'route_progress_config.dart';
import 'stop_progress.dart';

/// A single ETA figure with its provenance.
class EtaEstimate {
  const EtaEstimate({this.eta, this.confidence = EtaConfidence.none});

  final DateTime? eta;
  final EtaConfidence confidence;

  static const EtaEstimate none = EtaEstimate();
}

/// Turns a remaining distance into an arrival time.
///
/// Speed source priority: live GPS speed while moving (blended with the
/// schedule/history pace to damp momentary readings), then the trip's own
/// observed average, then the pace implied by the published schedule, then a
/// configured fallback. The result is clamped so outliers cannot produce
/// absurd ETAs, and each intermediate stop ahead adds a dwell budget.
class EtaEstimator {
  const EtaEstimator(this.config);

  final RouteProgressConfig config;

  double effectiveSpeedKmh({
    double? liveSpeedKmh,
    double? tripAverageKmh,
    double? schedulePaceKmh,
  }) {
    final reference = tripAverageKmh ?? schedulePaceKmh;
    double speed;
    if (liveSpeedKmh != null && liveSpeedKmh >= config.minMovingSpeedKmh) {
      speed = reference == null
          ? liveSpeedKmh
          : liveSpeedKmh * config.liveSpeedWeight +
                reference * (1 - config.liveSpeedWeight);
    } else {
      speed = reference ?? config.fallbackSpeedKmh;
    }
    return speed.clamp(
      config.minEffectiveSpeedKmh,
      config.maxEffectiveSpeedKmh,
    );
  }

  /// ETA from live data. [intermediateStops] counts stops the vehicle still
  /// halts at before reaching the target.
  EtaEstimate fromDistance({
    required double remainingMeters,
    required int intermediateStops,
    required DateTime now,
    double? liveSpeedKmh,
    double? tripAverageKmh,
    double? schedulePaceKmh,
  }) {
    final speedKmh = effectiveSpeedKmh(
      liveSpeedKmh: liveSpeedKmh,
      tripAverageKmh: tripAverageKmh,
      schedulePaceKmh: schedulePaceKmh,
    );
    final travelSeconds =
        remainingMeters / (speedKmh / 3.6) +
        config.dwellPerStop.inSeconds * intermediateStops;
    final isMoving =
        liveSpeedKmh != null && liveSpeedKmh >= config.minMovingSpeedKmh;
    return EtaEstimate(
      eta: now.add(Duration(seconds: travelSeconds.round())),
      confidence: isMoving ? EtaConfidence.live : EtaConfidence.estimated,
    );
  }

  /// Fallback when there is no usable GPS: surface the published plan.
  EtaEstimate fromSchedule(DateTime? plannedArrival) {
    if (plannedArrival == null) return EtaEstimate.none;
    return EtaEstimate(eta: plannedArrival, confidence: EtaConfidence.scheduled);
  }
}
