import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/session/captain_office_session.dart';
import '../../domain/entities/location_sharing_health.dart';
import '../../domain/usecases/send_location_update_usecase.dart';
import 'live_location_state.dart';

export '../../domain/entities/location_sharing_health.dart'
    show kAutoLocationInterval;

class LiveLocationCubit extends Cubit<LiveLocationState> {
  LiveLocationCubit({
    required SendLocationUpdateUseCase sendLocation,
    CaptainOfficeSession? session,
    DateTime Function() now = DateTime.now,
  }) : _sendLocation = sendLocation,
       _session = session,
       _now = now,
       super(const LiveLocationReady());

  final SendLocationUpdateUseCase _sendLocation;

  final CaptainOfficeSession? _session;

  bool get _trackingLicensed =>
      _session?.identity?.licensing.liveTracking ?? true;

  final DateTime Function() _now;
  Timer? _autoTimer;

  String? _tripId;

  bool _sending = false;

  bool get isAutoSharing => _autoTimer != null;

  String? get activeTripId => _tripId;

  Future<void> send(String tripId) =>
      _trackingLicensed ? _send(tripId, automatic: false) : Future.value();

  void startAutoSharing(String tripId) {
    if (!_trackingLicensed) return;

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

  void stopAutoSharing({String? tripId}) {
    if (_autoTimer == null) return;
    if (tripId != null && _tripId != tripId) return;
    _cancelTimer();
    if (!isClosed) emit(_ready(autoSharing: false));
  }

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
    _cancelTimer();
    return super.close();
  }
}
