import 'eta_estimator.dart';
import 'route_geometry.dart';
import 'route_progress_config.dart';
import 'route_progress_snapshot.dart';
import 'route_stop.dart';
import 'stop_progress.dart';

/// Stateful orchestrator that turns GPS fixes into route progress, per-stop
/// visit states, and ETAs.
///
/// Feed it fixes via [addFix] and lifecycle changes via [updatePhase], then
/// read [snapshot] whenever the UI needs fresh numbers (a new fix, a phase
/// change, or a periodic ETA re-count). All time is injected, so behavior is
/// deterministic under test.
///
/// Stop states advance monotonically (upcoming → arrived → departed) with
/// radius hysteresis: arriving takes [RouteProgressConfig.arrivalRadiusMeters],
/// departing takes [RouteProgressConfig.departRadiusMeters], and a stop the
/// bus rolls past without a detected dwell is marked departed once the
/// along-route position clears [RouteProgressConfig.passedStopSlackMeters].
class RouteProgressEngine {
  RouteProgressEngine({
    required List<RouteStop> stops,
    this.config = const RouteProgressConfig(),
    this.scheduledDeparture,
    this.scheduledArrival,
    TripProgressPhase phase = TripProgressPhase.headingToPickup,
  }) : _geometry = RouteGeometry(stops),
       _estimator = EtaEstimator(config),
       _phase = phase {
    _statuses = List.filled(_geometry.stops.length, _Visit.upcoming);
    if (phase == TripProgressPhase.completed) _completeAll();
  }

  final RouteProgressConfig config;
  final DateTime? scheduledDeparture;
  final DateTime? scheduledArrival;

  final RouteGeometry _geometry;
  final EtaEstimator _estimator;

  late List<_Visit> _statuses;
  TripProgressPhase _phase;
  double _alongMeters = 0;
  bool _offRoute = false;

  double? _lastLatitude;
  double? _lastLongitude;
  double? _lastSpeedKmh;
  DateTime? _lastFixReceivedAt;
  DateTime? _enRouteSince;
  double? _alongAtEnRouteStart;

  TripProgressPhase get phase => _phase;

  /// Marks the first [arrivedCount] stops as visited (last of them as the
  /// current stop). Used to seed authoritative operational events — e.g. the
  /// dashboard's per-station arrival log — as a floor under GPS inference.
  void seedVisited(int arrivedCount) {
    final n = arrivedCount.clamp(0, _statuses.length);
    for (var i = 0; i < n - 1; i++) {
      _statuses[i] = _Visit.departed;
    }
    if (n > 0) {
      _statuses[n - 1] = _maxVisit(_statuses[n - 1], _Visit.arrived);
      _alongMeters = _alongMeters > _geometry.cumulativeMeters[n - 1]
          ? _alongMeters
          : _geometry.cumulativeMeters[n - 1];
    }
  }

  void updatePhase(TripProgressPhase phase) {
    if (phase == _phase) return;
    _phase = phase;
    if (phase == TripProgressPhase.completed) _completeAll();
  }

  /// Ingests a validated GPS fix. [now] is the receipt time (wall clock of
  /// the consumer), which staleness is measured against.
  void addFix({
    required double latitude,
    required double longitude,
    double? speedKmh,
    required DateTime now,
  }) {
    _lastLatitude = latitude;
    _lastLongitude = longitude;
    _lastSpeedKmh = speedKmh;
    _lastFixReceivedAt = now;
    if (_phase == TripProgressPhase.completed) return;

    if (_phase != TripProgressPhase.enRoute) {
      
      if (_geometry.stops.isNotEmpty &&
          _statuses[0] == _Visit.upcoming &&
          _geometry.distanceToStop(0, latitude, longitude) <=
              config.arrivalRadiusMeters) {
        _statuses[0] = _Visit.arrived;
      }
      return;
    }

    if (_enRouteSince == null) {
      _enRouteSince = now;
      _alongAtEnRouteStart = _alongMeters;
    }

    final projection = _geometry.project(
      latitude,
      longitude,
      minAlongMeters: _alongMeters,
      backtrackToleranceMeters: config.backtrackToleranceMeters,
    );
    if (projection == null) return;

    _offRoute = projection.crossTrackMeters > config.offRouteMeters;
    if (_offRoute) return; 

    if (projection.alongTrackMeters > _alongMeters) {
      _alongMeters = projection.alongTrackMeters;
    }
    _advanceStops(latitude, longitude);
  }

  void _advanceStops(double latitude, double longitude) {
    for (var i = 0; i < _statuses.length; i++) {
      if (_statuses[i] == _Visit.departed) continue;
      final stopAlong = _geometry.cumulativeMeters[i];
      final distance = _geometry.distanceToStop(i, latitude, longitude);
      if (_statuses[i] == _Visit.arrived) {
        final left =
            distance > config.departRadiusMeters ||
            _alongMeters > stopAlong + config.departRadiusMeters;
        if (!left) return; 
        _statuses[i] = _Visit.departed;
        continue;
      }
      if (distance <= config.arrivalRadiusMeters) {
        _statuses[i] = _Visit.arrived;
        return;
      }
      if (_alongMeters >= stopAlong + config.passedStopSlackMeters) {
        _statuses[i] = _Visit.departed; 
        continue;
      }
      return; 
    }
  }

  void _completeAll() {
    for (var i = 0; i < _statuses.length; i++) {
      _statuses[i] = _Visit.departed;
    }
    _alongMeters = _geometry.totalMeters;
    _offRoute = false;
  }

  _Visit _maxVisit(_Visit a, _Visit b) => a.index >= b.index ? a : b;

  /// Pace implied by the published schedule, when derivable and sane.
  double? get _schedulePaceKmh {
    final dep = scheduledDeparture;
    final arr = scheduledArrival;
    if (dep == null || arr == null || !_geometry.isTrackable) return null;
    final hours = arr.difference(dep).inSeconds / 3600;
    if (hours <= 0) return null;
    final pace = (_geometry.totalMeters / 1000) / hours;
    return pace < 5 || pace > 120 ? null : pace;
  }

  /// Average pace observed since the trip went en route; null until there is
  /// enough movement to be meaningful.
  double? _tripAverageKmh(DateTime now) {
    final since = _enRouteSince;
    final startAlong = _alongAtEnRouteStart;
    if (since == null || startAlong == null) return null;
    final hours = now.difference(since).inSeconds / 3600;
    final km = (_alongMeters - startAlong) / 1000;
    if (hours < 0.05 || km < 0.5) return null;
    return km / hours;
  }

  RouteProgressSnapshot snapshot(DateTime now) {
    final hasFix = _lastFixReceivedAt != null;
    final isStale =
        hasFix && now.difference(_lastFixReceivedAt!) > config.staleAfter;
    final total = _geometry.totalMeters;
    final traveled = _phase == TripProgressPhase.enRoute
        ? _alongMeters.clamp(0.0, total).toDouble()
        : (_phase == TripProgressPhase.completed ? total : 0.0);
    final nextIndex = _nextIndex();
    return RouteProgressSnapshot(
      phase: _phase,
      hasVehicleFix: hasFix,
      isStale: isStale,
      isOffRoute: _offRoute,
      routeFraction: total <= 0
          ? (_phase == TripProgressPhase.completed ? 1.0 : 0.0)
          : (traveled / total).clamp(0.0, 1.0).toDouble(),
      traveledMeters: traveled,
      totalRouteMeters: total,
      stops: _buildStops(now, hasFix: hasFix, isStale: isStale),
      nextStopIndex: nextIndex,
    );
  }

  int? _nextIndex() {
    if (_phase == TripProgressPhase.completed) return null;
    for (var i = 0; i < _statuses.length; i++) {
      if (_statuses[i] == _Visit.upcoming) return i;
    }
    return null;
  }

  List<StopProgress> _buildStops(
    DateTime now, {
    required bool hasFix,
    required bool isStale,
  }) {
    final nextIndex = _nextIndex();
    final liveUsable = hasFix && !isStale && !_offRoute;
    final tripAverage = _tripAverageKmh(now);
    final schedulePace = _schedulePaceKmh;
    return List.generate(_geometry.stops.length, (i) {
      final stop = _geometry.stops[i];
      final status = switch (_statuses[i]) {
        _Visit.departed => StopVisitStatus.departed,
        _Visit.arrived => StopVisitStatus.arrived,
        _Visit.upcoming =>
          i == nextIndex ? StopVisitStatus.next : StopVisitStatus.upcoming,
      };
      if (status == StopVisitStatus.departed ||
          status == StopVisitStatus.arrived ||
          _phase == TripProgressPhase.completed) {
        return StopProgress(stop: stop, status: status);
      }
      final (remaining, intermediates) = _remainingTo(i, nextIndex);
      final estimate = liveUsable && remaining != null
          ? _estimator.fromDistance(
              remainingMeters: remaining,
              intermediateStops: intermediates,
              now: now,
              liveSpeedKmh: _lastSpeedKmh,
              tripAverageKmh: tripAverage,
              schedulePaceKmh: schedulePace,
            )
          : _estimator.fromSchedule(stop.plannedArrival);
      return StopProgress(
        stop: stop,
        status: status,
        remainingMeters: remaining,
        eta: estimate.eta,
        etaConfidence: estimate.confidence,
      );
    });
  }

  /// Along-route distance to stop [i] plus how many stops the bus still
  /// halts at first. Before the trip starts only the origin is estimable —
  /// via straight-line distance inflated for road indirectness.
  (double?, int) _remainingTo(int i, int? nextIndex) {
    final lat = _lastLatitude;
    final lng = _lastLongitude;
    if (_phase == TripProgressPhase.enRoute) {
      final gap = _geometry.cumulativeMeters[i] - _alongMeters;
      final remaining = gap < 0 ? 0.0 : gap;
      var intermediates = 0;
      for (var j = nextIndex ?? 0; j < i; j++) {
        if (_statuses[j] != _Visit.departed) intermediates++;
      }
      return (remaining, intermediates);
    }
    if (i == 0 && lat != null && lng != null) {
      final direct = _geometry.distanceToStop(0, lat, lng);
      return (direct * config.approachIndirectness, 0);
    }
    return (null, 0);
  }
}

/// Internal monotonic visit state (excludes the derived `next`).
enum _Visit { upcoming, arrived, departed }
