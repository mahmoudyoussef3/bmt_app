import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/tracking/live_tracking_config.dart';
import 'package:bmt_app/core/tracking/vehicle_fix.dart';

import '../../../../core/session/captain_office_session.dart';
import '../../domain/usecases/publish_trip_location_usecase.dart';
import '../../domain/usecases/send_location_update_usecase.dart';
import '../../domain/usecases/watch_publishable_location_usecase.dart';
import 'live_location_state.dart';

export '../../domain/entities/location_sharing_health.dart'
    show kAutoLocationInterval;

/// The captain's position publisher, and the owner of its lifetime.
///
/// Registered as an app-lifetime singleton so reporting follows the *trip*, not
/// whichever widget happened to start it: a captain who opens the map or backs
/// out to the trip list must not silently take every passenger's map down with
/// them. The ownership rules below are what make one shared publisher safe.
///
/// ## The pipeline
///
/// ```
/// GPS stream ─▶ validate ─▶ throttle ─▶ publish     (movement-driven)
///          heartbeat timer ──────────▶ publish      (proof of life while parked)
/// ```
///
/// Assembling and rate-limiting the stream is domain work
/// ([WatchPublishableLocationUseCase]); this class owns only *when the pipeline
/// runs* and what the captain is told about it.
///
/// The heartbeat exists because the GPS stream carries a distance filter, so a
/// stationary vehicle emits nothing at all — without it, "parked at the station"
/// and "GPS died" would be indistinguishable to a watching passenger. It is
/// skipped whenever movement has already published within the window, so a
/// moving bus never pays for it.
class LiveLocationCubit extends Cubit<LiveLocationState> {
  LiveLocationCubit({
    required SendLocationUpdateUseCase sendLocation,
    required WatchPublishableLocationUseCase watchPublishableLocation,
    required PublishTripLocationUseCase publishLocation,
    CaptainOfficeSession? session,
    DateTime Function() now = DateTime.now,
    LiveTrackingConfig config = kLiveTrackingConfig,
  }) : _sendLocation = sendLocation,
       _watchPublishableLocation = watchPublishableLocation,
       _publishLocation = publishLocation,
       _session = session,
       _now = now,
       _config = config,
       super(const LiveLocationReady());

  final SendLocationUpdateUseCase _sendLocation;
  final WatchPublishableLocationUseCase _watchPublishableLocation;
  final PublishTripLocationUseCase _publishLocation;
  final LiveTrackingConfig _config;

  final CaptainOfficeSession? _session;

  bool get _trackingLicensed =>
      _session?.identity?.licensing.liveTracking ?? true;

  final DateTime Function() _now;

  StreamSubscription<VehicleFix>? _gpsSub;
  Timer? _heartbeat;

  String? _tripId;
  bool _sharing = false;
  bool _sending = false;

  /// Whether a movement-driven fix landed since the last heartbeat tick.
  ///
  /// Deliberately a flag rather than a clock comparison: the heartbeat's job is
  /// "has anything reached the database recently", which the pipeline can answer
  /// about itself without consulting wall-clock time at all.
  bool _publishedSinceHeartbeat = false;

  bool get isAutoSharing => _sharing;

  String? get activeTripId => _tripId;

  Future<void> send(String tripId) =>
      _trackingLicensed ? _acquireAndSend(tripId, automatic: false) : Future.value();

  void startAutoSharing(String tripId) {
    if (!_trackingLicensed) return;

    // Rebuilds are constant, and a second pipeline would mean two GPS
    // subscriptions and duplicate writes.
    if (_sharing) {
      if (_tripId == tripId) return;
      _teardown();
    }

    _tripId = tripId;
    _sharing = true;
    _publishedSinceHeartbeat = false;

    _gpsSub = _watchPublishableLocation().listen(
      (fix) => _publish(tripId, fix),
      onError: (Object error) => _noteFailure(error, automatic: true),
    );

    _heartbeat = Timer.periodic(_config.heartbeatInterval, (_) {
      if (_publishedSinceHeartbeat) {
        // Movement is already covering this window; spend nothing.
        _publishedSinceHeartbeat = false;
        return;
      }
      _acquireAndSend(tripId, automatic: true);
    });

    // The first fix reaches the passenger's map now, not one window from now.
    _acquireAndSend(tripId, automatic: true);
    if (!isClosed) emit(_ready(autoSharing: true));
  }

  /// [tripId] names the trip being stopped: a card finishing for trip A must not
  /// silence the trip actually being driven.
  void stopAutoSharing({String? tripId}) {
    if (!_sharing) return;
    if (tripId != null && _tripId != tripId) return;
    _teardown();
    if (!isClosed) emit(_ready(autoSharing: false));
  }

  /// Closes the backgrounding gap instead of waiting out a window. Dart timers
  /// do not survive iOS suspension, so a resumed app may be minutes behind.
  void resumeIfStale() {
    if (!_sharing || _sending) return;
    final tripId = _tripId;
    if (tripId == null) return;

    final current = state;
    final lastSentAt = current is LiveLocationReady ? current.lastSentAt : null;
    if (lastSentAt != null &&
        _now().difference(lastSentAt) < _config.heartbeatInterval) {
      return;
    }
    _acquireAndSend(tripId, automatic: true);
  }

  void _teardown() {
    _gpsSub?.cancel();
    _gpsSub = null;
    _heartbeat?.cancel();
    _heartbeat = null;
    _sharing = false;
    _tripId = null;
    _publishedSinceHeartbeat = false;
  }

  /// A fix the pipeline has already validated and throttled.
  Future<void> _publish(String tripId, VehicleFix fix) async {
    if (_sending) return;
    _sending = true;
    try {
      final update = await _publishLocation(tripId, fix);
      if (isClosed) return;
      _publishedSinceHeartbeat = true;
      emit(_ready(lastSentAt: update.recordedAt, failures: 0));
    } catch (error) {
      _noteFailure(error, automatic: true);
    } finally {
      _sending = false;
    }
  }

  /// Acquire a position and publish it — the manual button and the heartbeat.
  /// A send in flight skips this one: a 20 s acquisition can outrun its window.
  Future<void> _acquireAndSend(
    String tripId, {
    required bool automatic,
  }) async {
    if (_sending) return;
    _sending = true;

    if (!automatic) emit(LiveLocationLoading(isAutoSharing: isAutoSharing));

    try {
      final update = await _sendLocation(tripId);
      if (isClosed) return;
      emit(_ready(lastSentAt: update.recordedAt, failures: 0));
    } catch (error) {
      _noteFailure(error, automatic: automatic);
    } finally {
      _sending = false;
    }
  }

  /// A dropped fix keeps the last good one on screen — the captain is driving,
  /// and one failed send is not worth an interruption. A *run* of failures is a
  /// different fact, so it is counted and named.
  void _noteFailure(Object error, {required bool automatic}) {
    if (isClosed) return;
    final message = error.toString().replaceFirst(RegExp(r'^Exception: ?'), '');
    emit(
      automatic
          ? _ready(autoError: message, failures: _failures + 1)
          : LiveLocationError(message, isAutoSharing: isAutoSharing),
    );
  }

  int get _failures {
    final current = state;
    return current is LiveLocationReady ? current.consecutiveFailures : 0;
  }

  LiveLocationReady _ready({
    DateTime? lastSentAt,
    bool? autoSharing,
    String? autoError,
    int? failures,
  }) {
    final current = state;
    final previous = current is LiveLocationReady ? current : null;
    return LiveLocationReady(
      lastSentAt: lastSentAt ?? previous?.lastSentAt,
      isAutoSharing: autoSharing ?? isAutoSharing,
      lastError: lastSentAt != null ? null : autoError ?? previous?.lastError,
      consecutiveFailures: failures ?? previous?.consecutiveFailures ?? 0,
    );
  }

  @override
  Future<void> close() {
    _teardown();
    return super.close();
  }
}
