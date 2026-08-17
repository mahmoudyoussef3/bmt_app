import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/tracking/fix_validator.dart';
import 'package:bmt_app/core/tracking/live_tracking_config.dart';
import 'package:bmt_app/core/tracking/tracking_config.dart';
import 'package:bmt_app/core/tracking/vehicle_fix.dart';

import '../../domain/entities/tracking_trip.dart';
import '../../domain/usecases/watch_vehicle_feed_usecase.dart';
import 'live_tracking_event.dart';
import 'live_tracking_state.dart';
import 'tracking_progress_controller.dart';

/// Orchestrates one rider's live view of one vehicle.
///
/// A Bloc rather than a Cubit, and the reason is the shape of the problem rather
/// than a preference: five independent producers push into this feature — the
/// screen (open/stop/retry), the transport (link health), the captain
/// (positions), a timer (freshness and ETA decay), and the operation (the trip
/// ending) — and they interleave in orders nobody chooses. Direct method calls
/// cannot express "these arrive concurrently and must be ordered", and they give
/// nowhere to state that a retry should be dropped while one is in flight while a
/// position must never be dropped at all. Events plus transformers say both.
///
/// It knows nothing about Supabase. Positions and link health arrive as domain
/// values through a use case; there is no client, channel, table name or
/// PostgREST call anywhere beneath this file.
class LiveTrackingBloc extends Bloc<LiveTrackingEvent, LiveTrackingState> {
  LiveTrackingBloc({
    required WatchVehicleFeedUseCase watchVehicleFeed,
    LiveTrackingConfig config = kLiveTrackingConfig,
    DateTime Function() now = DateTime.now,
  }) : _watchVehicleFeed = watchVehicleFeed,
       _config = config,
       _now = now,
       super(const LiveTrackingIdle()) {
    // Opening a feed for a different trip must abandon the previous setup rather
    // than race it — two completed handlers would mean two live feeds.
    on<TrackingRequested>(_onRequested, transformer: restartable());

    // Lifecycle transitions: never dropped, never reordered. Dropping a stop
    // leaks a socket; letting a `restored` overtake its `lost` pins the pill to
    // the wrong answer.
    on<TrackingStopped>(_onStopped, transformer: sequential());
    on<TrackingFinished>(_onFinished, transformer: sequential());
    on<TrackingLinkReported>(_onLinkReported, transformer: sequential());
    on<TrackingFeedFailed>(_onFeedFailed, transformer: sequential());

    // The high-frequency one. `concurrent` would fold positions into a stateful
    // engine out of order; `droppable` would discard the *newest* fix, which is
    // the opposite of what tracking wants; `restartable` could cancel a handler
    // mid-emit. The handler does no I/O — it folds and emits — so strict
    // ordering costs nothing and is exactly what is needed.
    //
    // Note this is a different concern from the captain's publishing throttle:
    // that one bounds database writes, this one bounds nothing and only orders
    // state. Rate limiting belongs at the producer; ordering belongs here.
    on<VehicleFixReceived>(_onFixReceived, transformer: sequential());

    // A second freshness tick while one is being handled would recompute an
    // identical derived value, and a rider hammering retry must not open N
    // subscriptions. "Ignore while one is in flight" is precisely droppable.
    on<TrackingFreshnessEvaluated>(
      _onFreshnessEvaluated,
      transformer: droppable(),
    );
    on<TrackingRetryRequested>(_onRetryRequested, transformer: droppable());
  }

  final WatchVehicleFeedUseCase _watchVehicleFeed;
  final LiveTrackingConfig _config;
  final DateTime Function() _now;

  final TrackingProgressController _progress = TrackingProgressController();

  /// Consumer-side gate against replayed, duplicated and out-of-order fixes.
  ///
  /// Accuracy is deliberately **not** enforced here. The producer rejects a
  /// coarse fix because a better one is seconds away; down here a coarse fix is
  /// the only fix there is, and refusing it would freeze route progress rather
  /// than improve it. Whether it is precise enough to *draw* stays the marker
  /// engine's decision.
  static const _validator = FixValidator(
    TrackingConfig(maxAccuracyMeters: double.infinity),
  );

  VehicleFix? _lastAccepted;

  StreamSubscription<VehicleFeedEvent>? _feedSub;
  Timer? _freshnessTimer;
  String? _feedTripId;
  TrackingTripData? _trip;
  DateTime? _lastEtaEmitAt;

  Future<void> _onRequested(
    TrackingRequested event,
    Emitter<LiveTrackingState> emit,
  ) async {
    final trip = event.trip;
    final tripId = trip.tripId;
    if (tripId == null) {
      await _release();
      emit(const LiveTrackingIdle());
      return;
    }

    _trip = trip;
    final progress = _progress.sync(trip, now: _now());

    // A finished trip has no more positions to report; an open socket would cost
    // a connection for nothing.
    if (trip.tripState.isFinished) {
      await _release();
      emit(LiveTrackingFinished(progress: progress));
      return;
    }

    // Once this rider is aboard, the waiting-stage feed is not theirs. Dropping
    // the subscription is the courteous half — the server is the half that
    // matters, and it will not deliver these rows to them either way.
    if (!trip.rider.canTrackVehicle) {
      await _release();
      emit(LiveTrackingUnavailable(progress: progress));
      return;
    }

    // A refetch of the trip already being tracked: keep the feed, refresh what
    // was derived from it. Re-subscribing would drop a healthy socket and lose
    // the engine's monotonic stop history.
    if (_feedTripId == tripId && _feedSub != null) {
      final current = state;
      emit(
        current is LiveTrackingActive
            ? current.copyWith(progress: progress)
            : LiveTrackingConnecting(progress: progress),
      );
      return;
    }

    await _release();
    emit(LiveTrackingConnecting(progress: progress));
    _subscribe(tripId);
    _startFreshnessTimer();
  }

  void _subscribe(String tripId) {
    _feedTripId = tripId;
    _feedSub = _watchVehicleFeed(tripId).listen(
      (event) {
        if (isClosed) return;
        switch (event) {
          case VehicleFixReported(:final fix):
            add(VehicleFixReceived(fix));
          case VehicleLinkChanged(:final link):
            add(TrackingLinkReported(link));
        }
      },
      onError: (Object error) {
        if (isClosed) return;
        add(TrackingFeedFailed(_readable(error)));
      },
    );
  }

  void _startFreshnessTimer() {
    _freshnessTimer?.cancel();
    // Checked more often than the stale window itself, so the transition is
    // announced within a third of it rather than up to a full window late.
    final period = Duration(
      milliseconds: (_config.staleAfter.inMilliseconds / 3).round(),
    );
    _freshnessTimer = Timer.periodic(period, (_) {
      if (!isClosed) add(const TrackingFreshnessEvaluated());
    });
  }

  void _onFixReceived(
    VehicleFixReceived event,
    Emitter<LiveTrackingState> emit,
  ) {
    // A replayed or re-polled fix produces no state at all. This is what makes
    // the catch-up poll free: overlapping with realtime cannot cause a rebuild.
    if (!_accepts(event.fix)) return;

    final now = _now();
    final progress =
        _progress.addFix(event.fix, _trip?.tripState ?? TrackingTripState.notStarted, now: now) ??
        state.progress;
    _lastEtaEmitAt = now;

    final current = state;
    emit(
      LiveTrackingActive(
        fix: event.fix,
        receivedAt: now,
        freshness: TrackingFreshness.live,
        // A position arriving proves the link is carrying rows. Whether it came
        // by socket or catch-up poll is the data layer's business, and it reports
        // that separately.
        link: current is LiveTrackingActive
            ? current.link
            : TrackingLink.connected,
        progress: progress,
      ),
    );
  }

  void _onLinkReported(
    TrackingLinkReported event,
    Emitter<LiveTrackingState> emit,
  ) {
    final current = state;
    if (current is! LiveTrackingActive) {
      // With no position on screen there is nothing for link health to qualify;
      // the state stays `connecting`, which is the honest answer either way.
      return;
    }
    if (current.link == event.link) return;
    emit(current.copyWith(link: event.link));
  }

  void _onFreshnessEvaluated(
    TrackingFreshnessEvaluated event,
    Emitter<LiveTrackingState> emit,
  ) {
    final current = state;
    if (current is! LiveTrackingActive) return;

    final now = _now();
    final freshness = now.difference(current.receivedAt) > _config.staleAfter
        ? TrackingFreshness.stale
        : TrackingFreshness.live;

    final lastEta = _lastEtaEmitAt;
    final etaDue =
        lastEta == null ||
        now.difference(lastEta) >= _config.etaRefreshInterval;

    // Nothing changed and no ETA is due: emit nothing rather than an equal state.
    if (freshness == current.freshness && !etaDue) return;

    _lastEtaEmitAt = now;
    emit(
      current.copyWith(
        freshness: freshness,
        progress: _progress.tick(now) ?? current.progress,
      ),
    );
  }

  Future<void> _onStopped(
    TrackingStopped event,
    Emitter<LiveTrackingState> emit,
  ) async {
    await _release();
    emit(const LiveTrackingIdle());
  }

  Future<void> _onFinished(
    TrackingFinished event,
    Emitter<LiveTrackingState> emit,
  ) async {
    final progress = state.progress;
    await _release();
    emit(LiveTrackingFinished(progress: progress));
  }

  Future<void> _onFeedFailed(
    TrackingFeedFailed event,
    Emitter<LiveTrackingState> emit,
  ) async {
    final progress = state.progress;
    await _release();
    emit(LiveTrackingFailure(event.message, progress: progress));
  }

  Future<void> _onRetryRequested(
    TrackingRetryRequested event,
    Emitter<LiveTrackingState> emit,
  ) async {
    final trip = _trip;
    if (trip == null) return;
    await _release();
    if (isClosed) return;
    add(TrackingRequested(trip));
  }

  /// Everything this Bloc holds open, closed in one place — so `stop`, `finish`,
  /// `fail`, `retry` and `close` cannot each get it half right.
  Future<void> _release() async {
    _freshnessTimer?.cancel();
    _freshnessTimer = null;
    final active = _feedSub;
    _feedSub = null;
    _feedTripId = null;
    await active?.cancel();
  }

  bool _accepts(TrackingPoint point) {
    final recordedAt = point.recordedAt;
    // Without a timestamp a fix cannot be ordered against anything, so it is
    // trusted only when there is nothing to contradict it.
    if (recordedAt == null) return _lastAccepted == null;

    final next = VehicleFix(
      latitude: point.latitude,
      longitude: point.longitude,
      recordedAt: recordedAt,
      headingDegrees: point.heading,
      speedMetersPerSecond: point.speed,
      accuracyMeters: point.accuracy,
    );
    if (_validator.validate(_lastAccepted, next) != null) return false;
    _lastAccepted = next;
    return true;
  }

  String _readable(Object error) =>
      error.toString().replaceFirst(RegExp(r'^Exception: ?'), '');

  @override
  Future<void> close() async {
    await _release();
    return super.close();
  }
}
