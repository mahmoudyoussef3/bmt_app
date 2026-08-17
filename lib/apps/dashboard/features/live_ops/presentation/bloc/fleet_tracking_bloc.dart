import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/tracking/link_health.dart';
import 'package:bmt_app/core/tracking/live_tracking_config.dart';

import '../../domain/entities/fleet_feed.dart';
import '../../domain/usecases/live_ops_usecases.dart';
import 'fleet_tracking_event.dart';
import 'fleet_tracking_state.dart';

/// Owns where the office's vehicles are, right now.
///
/// A Bloc rather than a Cubit, on the same reasoning that made the client's rider
/// feed one — the shape of the problem, not a preference. Independent producers
/// push here in orders nobody chooses: the roster (trips starting and ending),
/// the transport (link health), every captain on the road (positions), a timer
/// (freshness decay), and the operator (retry). Method calls cannot express
/// "these arrive concurrently and must be ordered", and give nowhere to say that
/// a catch-up read should be dropped while one is in flight while a position must
/// never be dropped at all.
///
/// [LiveOpsCubit] keeps the roster and the incident queue, which are
/// request/response work with none of that concurrency. The split is deliberate:
/// it is also what stops a bus moving from rebuilding the incident queue.
///
/// This holds no Supabase client, opens no channel and names no table. Positions
/// and link health arrive as domain values through a use case.
class FleetTrackingBloc extends Bloc<FleetTrackingEvent, FleetTrackingState> {
  FleetTrackingBloc({
    required WatchFleetFeedUseCase watchFleetFeed,
    required GetLatestFleetFixesUseCase getLatestFixes,
    LiveTrackingConfig config = kLiveTrackingConfig,
    DateTime Function() now = DateTime.now,
  }) : _watchFleetFeed = watchFleetFeed,
       _getLatestFixes = getLatestFixes,
       _config = config,
       _now = now,
       super(const FleetTrackingState()) {
    // Opening the feed twice must not open two sockets. `restartable` makes a
    // second start abandon the first rather than race it.
    on<FleetTrackingStarted>(_onStarted, transformer: restartable());

    // Roster and lifecycle: never dropped, never reordered. Dropping a stop
    // leaks a socket; letting a `restored` overtake its `lost` pins the banner
    // to the wrong answer.
    on<FleetTripsChanged>(_onTripsChanged, transformer: sequential());
    on<FleetLinkReported>(_onLinkReported, transformer: sequential());
    on<FleetFeedFailed>(_onFeedFailed, transformer: sequential());
    on<FleetTrackingStopped>(_onStopped, transformer: sequential());

    // The high-frequency one, and the interesting choice.
    //
    // `concurrent` would let two fixes for the same vehicle land out of order and
    // leave the older one on the map. `droppable` would discard the *newest* fix
    // under load, which is the exact opposite of what tracking wants — the newest
    // position is the only one worth having. `restartable` could cancel a handler
    // mid-emit. The handler does no I/O — it folds a position into a map and
    // emits — so strict ordering costs nothing and is precisely what is needed.
    //
    // Note this bounds nothing: rate limiting belongs at the producer, where the
    // captain's publisher throttles writes to one per 10s. Here, ordering only.
    on<FleetFixReceived>(_onFixReceived, transformer: sequential());

    // A second freshness tick while one is being handled recomputes an identical
    // verdict; a hammered retry must not open N subscriptions; a catch-up read
    // fired while one is in flight is a duplicate query. "Ignore while one is in
    // flight" is exactly droppable.
    on<FleetFreshnessEvaluated>(
      _onFreshnessEvaluated,
      transformer: droppable(),
    );
    on<FleetCatchUpRequested>(_onCatchUpRequested, transformer: droppable());
    on<FleetTrackingRetryRequested>(
      _onRetryRequested,
      transformer: droppable(),
    );
  }

  final WatchFleetFeedUseCase _watchFleetFeed;
  final GetLatestFleetFixesUseCase _getLatestFixes;
  final LiveTrackingConfig _config;
  final DateTime Function() _now;

  StreamSubscription<FleetFeedEvent>? _feedSub;
  Timer? _freshnessTimer;
  Timer? _catchUpTimer;

  /// Trips currently on the road. Positions for anything else are dropped —
  /// RLS scopes delivery to this office, but a trip that just ended can still
  /// emit a trailing fix, and drawing it would show a bus that is no longer
  /// running.
  Set<String> _rosterIds = const {};

  Future<void> _onStarted(
    FleetTrackingStarted event,
    Emitter<FleetTrackingState> emit,
  ) async {
    if (_feedSub != null) return;

    emit(state.copyWith(isConnecting: true, clearFailure: true));
    _subscribe();
    _startFreshnessTimer();
  }

  void _subscribe() {
    _feedSub = _watchFleetFeed().listen(
      (event) {
        if (isClosed) return;
        switch (event) {
          case FleetFixReported(:final tripId, :final fix):
            add(FleetFixReceived(tripId: tripId, fix: fix));
          case FleetLinkChanged(:final link):
            add(FleetLinkReported(link));
        }
      },
      onError: (Object error) {
        if (isClosed) return;
        add(FleetFeedFailed(_readable(error)));
      },
    );
  }

  /// Checked more often than the stale window itself, so a vehicle going stale is
  /// announced within a third of the window rather than up to a full window late.
  void _startFreshnessTimer() {
    _freshnessTimer?.cancel();
    final period = Duration(
      milliseconds: (_config.staleAfter.inMilliseconds / 3).round(),
    );
    _freshnessTimer = Timer.periodic(period, (_) {
      if (!isClosed) add(const FleetFreshnessEvaluated());
    });
  }

  /// The catch-up poll exists **only** while the socket is unhealthy.
  ///
  /// While the link is connected there are no periodic position queries at all —
  /// which is the whole performance change on this board. It used to refetch the
  /// entire roster, incidents included, every 15 seconds just to move a marker.
  void _syncCatchUpPoll(TrackingLink link) {
    if (link.isConnected) {
      _catchUpTimer?.cancel();
      _catchUpTimer = null;
      return;
    }
    if (_catchUpTimer != null) return;

    // Fire at once rather than waiting out the first window: the link just went
    // bad, so the board is already behind.
    add(const FleetCatchUpRequested());
    _catchUpTimer = Timer.periodic(_config.reconnectPollInterval, (_) {
      if (!isClosed) add(const FleetCatchUpRequested());
    });
  }

  void _onTripsChanged(
    FleetTripsChanged event,
    Emitter<FleetTrackingState> emit,
  ) {
    _rosterIds = {for (final trip in event.trips) trip.id};

    // Rebuilt rather than pruned in place, so a trip leaving the roster takes its
    // position with it and cannot linger on the map.
    final next = <String, TrackedVehicle>{};
    for (final trip in event.trips) {
      final known = state.vehicles[trip.id];
      if (known != null) {
        next[trip.id] = known;
        continue;
      }
      // Seed from the roster's backfilled fix so the map is populated on the
      // first paint instead of empty until the next INSERT arrives.
      //
      // `receivedAt` is the fix's own recorded time, not now: a position that was
      // already ten minutes old when the board loaded must read as ten minutes
      // old, not as freshly received. This is what stops a reload laundering a
      // dead feed into a live one.
      final fix = trip.lastFix;
      if (fix != null) {
        next[trip.id] = TrackedVehicle(fix: fix, receivedAt: fix.recordedAt);
      }
    }

    if (_sameVehicles(state.vehicles, next)) return;
    emit(state.copyWith(vehicles: next, evaluatedAt: _now()));
  }

  void _onFixReceived(
    FleetFixReceived event,
    Emitter<FleetTrackingState> emit,
  ) {
    // A position for a trip that is not on the road is not drawable.
    if (!_rosterIds.contains(event.tripId)) return;

    // A replayed or re-polled fix produces no state at all. This is what makes
    // the catch-up poll free: overlapping it with the socket cannot cost a frame.
    final known = state.vehicles[event.tripId];
    if (known != null && !event.fix.recordedAt.isAfter(known.fix.recordedAt)) {
      return;
    }

    final now = _now();
    emit(
      state.copyWith(
        vehicles: {
          ...state.vehicles,
          event.tripId: TrackedVehicle(fix: event.fix, receivedAt: now),
        },
        evaluatedAt: now,
        // A position arriving proves the link is carrying rows, whichever path
        // brought it. Reporting otherwise would leave the banner contradicting
        // the map.
        isConnecting: false,
        clearFailure: true,
      ),
    );
  }

  void _onLinkReported(
    FleetLinkReported event,
    Emitter<FleetTrackingState> emit,
  ) {
    _syncCatchUpPoll(event.link);
    if (state.link == event.link && !state.isConnecting) return;
    emit(state.copyWith(link: event.link, isConnecting: false));
  }

  /// Advances the board's clock.
  ///
  /// Health is a function of *now*, so going stale is a transition somebody has
  /// to announce; derived lazily it would only be noticed when an unrelated
  /// rebuild happened to recompute it. With no vehicles there is no clock worth
  /// moving, so an empty board ticks silently.
  ///
  /// This emits on every tick rather than only when a health verdict flipped —
  /// the "آخر تحديث منذ …" line on each card is also a function of this clock,
  /// and suppressing the emit would freeze that label for up to the width of a
  /// health window. Which widgets that costs is decided *above*, by selector:
  /// the map's markers select on positions and a health signature, so a clock
  /// tick that moved neither repaints nothing.
  void _onFreshnessEvaluated(
    FleetFreshnessEvaluated event,
    Emitter<FleetTrackingState> emit,
  ) {
    if (state.vehicles.isEmpty) return;
    emit(state.copyWith(evaluatedAt: _now()));
  }

  Future<void> _onCatchUpRequested(
    FleetCatchUpRequested event,
    Emitter<FleetTrackingState> emit,
  ) async {
    try {
      final fixes = await _getLatestFixes();
      if (isClosed) return;

      final now = _now();
      final next = <String, TrackedVehicle>{...state.vehicles};
      var changed = false;

      for (final entry in fixes.entries) {
        if (!_rosterIds.contains(entry.key)) continue;
        final known = next[entry.key];
        if (known != null &&
            !entry.value.recordedAt.isAfter(known.fix.recordedAt)) {
          continue;
        }
        next[entry.key] = TrackedVehicle(fix: entry.value, receivedAt: now);
        changed = true;
      }

      if (!changed) return;
      emit(state.copyWith(vehicles: next, evaluatedAt: now));
    } catch (_) {
      // A failed catch-up read is not worth telling the operator about — the
      // link banner already says the feed is degraded, and the last known
      // positions are still on screen.
    }
  }

  Future<void> _onFeedFailed(
    FleetFeedFailed event,
    Emitter<FleetTrackingState> emit,
  ) async {
    await _release();
    // Positions are deliberately kept: the last place each bus was seen is still
    // the best answer the desk has, and blanking the map would replace it with
    // nothing.
    emit(
      state.copyWith(
        failure: event.message,
        link: TrackingLink.lost,
        isConnecting: false,
      ),
    );
  }

  Future<void> _onRetryRequested(
    FleetTrackingRetryRequested event,
    Emitter<FleetTrackingState> emit,
  ) async {
    await _release();
    if (isClosed) return;
    emit(state.copyWith(isConnecting: true, clearFailure: true));
    _subscribe();
    _startFreshnessTimer();
  }

  Future<void> _onStopped(
    FleetTrackingStopped event,
    Emitter<FleetTrackingState> emit,
  ) async {
    await _release();
    emit(const FleetTrackingState(isConnecting: false));
  }

  bool _sameVehicles(
    Map<String, TrackedVehicle> a,
    Map<String, TrackedVehicle> b,
  ) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (!identical(b[entry.key], entry.value)) return false;
    }
    return true;
  }

  /// Everything this Bloc holds open, released in one place — so `stop`, `fail`,
  /// `retry` and `close` cannot each get it half right.
  Future<void> _release() async {
    _freshnessTimer?.cancel();
    _freshnessTimer = null;
    _catchUpTimer?.cancel();
    _catchUpTimer = null;
    final active = _feedSub;
    _feedSub = null;
    await active?.cancel();
  }

  String _readable(Object error) =>
      error.toString().replaceFirst(RegExp(r'^Exception: ?'), '');

  @override
  Future<void> close() async {
    await _release();
    return super.close();
  }
}
