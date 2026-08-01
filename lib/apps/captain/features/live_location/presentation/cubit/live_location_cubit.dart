import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/location_sharing_health.dart';
import '../../domain/usecases/send_location_update_usecase.dart';
import 'live_location_state.dart';

/// The reporting cadence now lives in the domain beside the staleness rule it
/// feeds ([LocationSharingStatus]), so the two cannot drift apart. Re-exported
/// here because every existing call site imports it from this file.
export '../../domain/entities/location_sharing_health.dart'
    show kAutoLocationInterval;

/// The platform's single live-position publisher.
///
/// Registered as a **lazy singleton** (`captain_di.dart`), which is the whole
/// design. Two things follow from it, and both are requirements rather than
/// conveniences:
///
///  * **Exactly one publisher can exist.** As a factory registration, every
///    mount of `TripLocationAutoShare` built its own cubit with its own timer.
///    Two of them alive at once — a rebuild that outlives its predecessor, a
///    second screen, a route that rebuilds the card — meant two GPS acquisitions
///    and two inserts every 30 s, doubling battery draw and writing duplicate
///    fixes that the client's map then has to reconcile. Ownership is now a
///    property of the app, not of whichever widget happened to build first.
///
///  * **Reporting outlives the screen.** The trip-execution page is not the
///    trip. A captain mid-journey opens the map, files an incident report,
///    checks the manifest, backs out to the trip list — and with the timer
///    owned by a widget, every one of those either risked or guaranteed the
///    client's map going dark, silently, while the bus kept driving. Publishing
///    is now bound to the trip being under way, and to nothing else: it starts
///    on departure and stops when the trip stops or the captain signs out.
///
/// What it deliberately still is: **foreground only**. Dart timers do not
/// survive iOS suspension and Android will eventually doze them, so a minimised
/// app stops reporting. That is a platform limit, not something this class can
/// paper over, and the one thing it must never do is pretend otherwise — see
/// [resumeIfStale], and `LocationSharingStatus`, which reports health from when
/// a fix last *landed* rather than from whether a timer exists.
class LiveLocationCubit extends Cubit<LiveLocationState> {
  LiveLocationCubit({
    required SendLocationUpdateUseCase sendLocation,
    DateTime Function() now = DateTime.now,
  }) : _sendLocation = sendLocation,
       _now = now,
       super(const LiveLocationReady());

  final SendLocationUpdateUseCase _sendLocation;

  /// Injected for the same reason `LocationSharingStatus.evaluate` takes a
  /// `now`: [resumeIfStale] compares against a threshold, and a threshold you
  /// have to wait out in real time is a threshold that goes untested.
  final DateTime Function() _now;
  Timer? _autoTimer;

  /// The trip currently being reported, null when nothing is. Held so a stop
  /// request naming some other trip can be ignored — see [stopAutoSharing].
  String? _tripId;

  /// Guards against a slow fix overlapping the next tick — GPS acquisition
  /// has a 20 s time limit, which can run right up against the 30 s interval
  /// on a bad signal, so a send may still be in flight when the next tick
  /// fires. When that happens the tick is skipped rather than queued.
  bool _sending = false;

  bool get isAutoSharing => _autoTimer != null;

  /// Which trip is being reported, for a caller that needs to know whether the
  /// publisher is already theirs.
  String? get activeTripId => _tripId;

  /// Sends one position now, at the captain's request.
  Future<void> send(String tripId) => _send(tripId, automatic: false);

  /// Starts reporting position every [kAutoLocationInterval] until
  /// [stopAutoSharing], beginning with an immediate fix so the trip doesn't
  /// go a full interval unlocated after departure.
  ///
  /// Idempotent for the trip already running: calling it again from a rebuilt
  /// widget is a no-op, not a second timer. Calling it for a *different* trip
  /// switches cleanly — a captain can only be driving one trip at a time, so
  /// the previous one stops rather than the two overlapping.
  void startAutoSharing(String tripId) {
    if (_autoTimer != null) {
      if (_tripId == tripId) return;
      _cancelTimer();
    }

    _tripId = tripId;
    _autoTimer = Timer.periodic(
      kAutoLocationInterval,
      (_) => _send(tripId, automatic: true),
    );
    _send(tripId, automatic: true);
    if (!isClosed) emit(_ready(autoSharing: true));
  }

  /// Stops reporting.
  ///
  /// [tripId] is the caller's own trip when it has one. A widget being torn
  /// down for a trip that is no longer the active one must not stop the trip
  /// that *is* — that is the shape of bug a singleton publisher invites, and
  /// naming the trip is what forecloses it. Passing null stops unconditionally,
  /// which is what sign-out wants.
  void stopAutoSharing({String? tripId}) {
    if (_autoTimer == null) return;
    if (tripId != null && _tripId != tripId) return;
    _cancelTimer();
    if (!isClosed) emit(_ready(autoSharing: false));
  }

  /// Reporting resumed after the app came back to the foreground.
  ///
  /// A minimised app stops publishing: iOS suspends the timer outright, Android
  /// dozes it. Whatever gap that leaves is real and is already visible to the
  /// captain — the card reads from the last landed fix — but the first thing to
  /// do on resume is close it, rather than wait out however much of the next
  /// interval remains. Sends only when the last fix is actually old enough to
  /// matter, so a quick app-switch does not cost an extra GPS acquisition.
  void resumeIfStale() {
    if (_autoTimer == null || _sending) return;
    final tripId = _tripId;
    if (tripId == null) return;

    final current = state;
    final lastSentAt = current is LiveLocationReady ? current.lastSentAt : null;
    if (lastSentAt != null &&
        _now().difference(lastSentAt) < kAutoLocationInterval) {
      return;
    }
    _send(tripId, automatic: true);
  }

  void _cancelTimer() {
    _autoTimer?.cancel();
    _autoTimer = null;
    _tripId = null;
  }

  Future<void> _send(String tripId, {required bool automatic}) async {
    if (_sending) return;
    _sending = true;

    // An automatic tick must not blank the screen into a spinner: the captain
    // is driving, and the card is showing them the last known fix.
    if (!automatic) emit(LiveLocationLoading(isAutoSharing: isAutoSharing));

    try {
      final update = await _sendLocation(tripId);
      if (isClosed) return;
      emit(_ready(lastSentAt: update.recordedAt, failures: 0));
    } catch (error) {
      if (isClosed) return;
      final message = error.toString().replaceFirst(
        RegExp(r'^Exception: ?'),
        '',
      );
      // A failed automatic send keeps the last good fix on screen and reports
      // the reason inline; the next tick retries by itself. A failed manual
      // send is the captain's own action, so it surfaces as an error state.
      emit(
        automatic
            ? _ready(autoError: message, failures: _failures + 1)
            : LiveLocationError(message, isAutoSharing: isAutoSharing),
      );
    } finally {
      _sending = false;
    }
  }

  int get _failures {
    final current = state;
    return current is LiveLocationReady ? current.consecutiveFailures : 0;
  }

  /// Rebuilds the ready state, carrying forward whatever the previous one
  /// knew so an automatic failure can't erase the last successful timestamp.
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
      // Cleared by any successful send.
      lastError: lastSentAt != null ? null : autoError ?? previous?.lastError,
      consecutiveFailures: failures ?? previous?.consecutiveFailures ?? 0,
    );
  }

  @override
  Future<void> close() {
    _cancelTimer();
    return super.close();
  }
}
