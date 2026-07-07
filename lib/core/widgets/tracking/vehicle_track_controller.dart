import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../../tracking/tracking.dart';

/// Flutter binding for [VehicleTrackingEngine].
///
/// Owns a [Ticker] that only runs while an interpolation is in flight —
/// an idle marker costs zero frames. A slow periodic timer re-notifies so
/// staleness badges update without animation frames. Listeners re-read
/// [sample] on every notification.
class VehicleTrackController extends ChangeNotifier {
  VehicleTrackController({
    required TickerProvider vsync,
    TrackingConfig config = const TrackingConfig(),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       _engine = VehicleTrackingEngine(config: config) {
    _ticker = vsync.createTicker(_onTick);
  }

  final DateTime Function() _clock;
  final VehicleTrackingEngine _engine;
  late final Ticker _ticker;
  Timer? _staleTimer;
  bool _disposed = false;

  /// Interpolated vehicle state right now, or null before the first fix.
  VehicleSample? get sample => _engine.sample(_clock());

  /// Latest accepted raw fix.
  VehicleFix? get targetFix => _engine.targetFix;

  bool get hasFix => _engine.targetFix != null;

  /// Why the most recent fix was dropped, if it was.
  FixRejection? get lastRejection => _engine.lastRejection;

  /// Feeds a raw fix into the engine. Returns whether it was accepted.
  bool addFix(VehicleFix fix) {
    final accepted = _engine.addFix(fix, now: _clock());
    if (!accepted) return false;

    _staleTimer ??= Timer.periodic(
      const Duration(seconds: 15),
      (_) => notifyListeners(),
    );
    if (_engine.isAnimating(_clock()) && !_ticker.isActive) {
      _ticker.start();
    }
    notifyListeners();
    return true;
  }

  /// Clears all track state (e.g. when switching trips).
  void reset() {
    _ticker.stop();
    _staleTimer?.cancel();
    _staleTimer = null;
    _engine.reset();
    notifyListeners();
  }

  void _onTick(Duration _) {
    notifyListeners();
    if (!_engine.isAnimating(_clock())) _ticker.stop();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _ticker.dispose();
    _staleTimer?.cancel();
    super.dispose();
  }
}
