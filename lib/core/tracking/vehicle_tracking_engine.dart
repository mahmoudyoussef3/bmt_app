import 'fix_validator.dart';
import 'geo_math.dart';
import 'heading_resolver.dart';
import 'speed_estimator.dart';
import 'tracking_config.dart';
import 'vehicle_fix.dart';
import 'vehicle_sample.dart';

/// Core live-tracking engine: feed raw fixes in with [addFix], read a
/// render-ready [VehicleSample] out with [sample] at any wall-clock time.
///
/// Pure Dart and clock-agnostic (callers pass `now`), so every behavior —
/// interpolation, snapping, heading, staleness — is deterministic in tests.
/// New fixes animate from wherever the marker currently is, so a fix that
/// arrives mid-animation never causes a visual jump backwards.
class VehicleTrackingEngine {
  VehicleTrackingEngine({
    TrackingConfig config = const TrackingConfig(),
    double Function(double t) easing = GeoMath.easeOutCubic,
  }) : _config = config,
       _easing = easing,
       _validator = FixValidator(config),
       _speed = SpeedEstimator(config),
       _heading = HeadingResolver(config);

  final TrackingConfig _config;
  final double Function(double t) _easing;
  final FixValidator _validator;
  final SpeedEstimator _speed;
  final HeadingResolver _heading;

  VehicleFix? _target;
  double _targetHeading = 0;
  DateTime? _receivedAt;
  DateTime? _animStart;
  Duration _animDuration = Duration.zero;
  double _fromLat = 0;
  double _fromLng = 0;
  double _fromHeading = 0;
  double? _fromAccuracy;

  /// Latest accepted fix, or null before the first one.
  VehicleFix? get targetFix => _target;

  /// Why the most recent [addFix] call rejected its fix, if it did.
  FixRejection? lastRejection;

  /// Applies [fix] if it survives validation. Returns whether it was
  /// accepted; [now] is the wall-clock receipt time.
  bool addFix(VehicleFix fix, {required DateTime now}) {
    lastRejection = _validator.validate(_target, fix);
    if (lastRejection != null) return false;

    final speedKmh = _speed.update(_target, fix);
    final heading = _heading.resolve(_target, fix, speedKmh);
    final origin = _target == null ? null : sample(now);

    if (origin == null) {
      _animDuration = Duration.zero;
      _fromLat = fix.latitude;
      _fromLng = fix.longitude;
      _fromHeading = heading;
      _fromAccuracy = fix.accuracyMeters;
    } else {
      final jumpMeters = GeoMath.distanceMeters(
        origin.latitude,
        origin.longitude,
        fix.latitude,
        fix.longitude,
      );
      final interval = fix.recordedAt.difference(_target!.recordedAt);
      _animDuration = jumpMeters > _config.snapDistanceMeters
          ? Duration.zero
          : _clampDuration(interval);
      _fromLat = origin.latitude;
      _fromLng = origin.longitude;
      _fromHeading = origin.headingDegrees;
      _fromAccuracy = origin.accuracyMeters;
    }

    _target = fix;
    _targetHeading = heading;
    _receivedAt = now;
    _animStart = now;
    return true;
  }

  /// Interpolated vehicle state at [now], or null before any fix.
  VehicleSample? sample(DateTime now) {
    final target = _target;
    if (target == null || _animStart == null) return null;

    final t = _progress(now);
    final eased = _easing(t);
    final speedKmh = _speed.currentKmh;
    return VehicleSample(
      latitude: GeoMath.lerpLatitude(_fromLat, target.latitude, eased),
      longitude: GeoMath.lerpLongitude(_fromLng, target.longitude, eased),
      headingDegrees: GeoMath.lerpAngleDegrees(
        _fromHeading,
        _targetHeading,
        eased,
      ),
      speedKmh: speedKmh,
      accuracyMeters: _lerpAccuracy(target.accuracyMeters, eased),
      fixRecordedAt: target.recordedAt,
      isInterpolating: t < 1,
      isMoving: speedKmh >= _config.movingSpeedThresholdKmh,
      isStale: now.difference(_receivedAt!) > _config.staleAfter,
    );
  }

  /// True while the marker still has interpolation frames to render.
  bool isAnimating(DateTime now) => _target != null && _progress(now) < 1;

  void reset() {
    _target = null;
    _receivedAt = null;
    _animStart = null;
    _animDuration = Duration.zero;
    _fromAccuracy = null;
    _targetHeading = 0;
    lastRejection = null;
    _speed.reset();
    _heading.reset();
  }

  double _progress(DateTime now) {
    if (_animDuration == Duration.zero) return 1;
    final elapsed = now.difference(_animStart!).inMicroseconds;
    return (elapsed / _animDuration.inMicroseconds).clamp(0.0, 1.0);
  }

  Duration _clampDuration(Duration interval) {
    if (interval < _config.minAnimation) return _config.minAnimation;
    if (interval > _config.maxAnimation) return _config.maxAnimation;
    return interval;
  }

  double? _lerpAccuracy(double? to, double eased) {
    final from = _fromAccuracy;
    if (from == null || to == null) return to ?? from;
    return from + (to - from) * eased;
  }
}
