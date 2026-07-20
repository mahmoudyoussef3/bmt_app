import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/send_location_update_usecase.dart';
import 'live_location_state.dart';

/// How often an active trip reports its position automatically.
///
/// One minute is the resolution the client's tracking map is built to consume
/// (it merges realtime inserts with a short poll fallback), and it is cheap
/// enough to run for a whole trip without draining the captain's phone.
const Duration kAutoLocationInterval = Duration(minutes: 1);

class LiveLocationCubit extends Cubit<LiveLocationState> {
  LiveLocationCubit({required SendLocationUpdateUseCase sendLocation})
    : _sendLocation = sendLocation,
      super(const LiveLocationReady());

  final SendLocationUpdateUseCase _sendLocation;
  Timer? _autoTimer;

  /// Guards against a slow fix overlapping the next tick — GPS acquisition
  /// has a 20 s time limit, so a minute timer can still catch a send in
  /// flight on a bad signal.
  bool _sending = false;

  bool get isAutoSharing => _autoTimer != null;

  /// Sends one position now, at the captain's request.
  Future<void> send(String tripId) => _send(tripId, automatic: false);

  /// Starts reporting position every [kAutoLocationInterval] until
  /// [stopAutoSharing], beginning with an immediate fix so the trip doesn't
  /// go a full minute unlocated after departure.
  ///
  /// Foreground only: this runs while the trip execution screen is open. The
  /// app claims no background location, and starting a timer here does not
  /// change that — the captain keeps the trip on screen while driving it.
  void startAutoSharing(String tripId) {
    if (_autoTimer != null) return;
    _autoTimer = Timer.periodic(
      kAutoLocationInterval,
      (_) => _send(tripId, automatic: true),
    );
    _send(tripId, automatic: true);
    if (!isClosed) emit(_ready(autoSharing: true));
  }

  void stopAutoSharing() {
    if (_autoTimer == null) return;
    _autoTimer?.cancel();
    _autoTimer = null;
    if (!isClosed) emit(_ready(autoSharing: false));
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
      emit(_ready(lastSentAt: update.recordedAt));
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
            ? _ready(autoError: message)
            : LiveLocationError(message, isAutoSharing: isAutoSharing),
      );
    } finally {
      _sending = false;
    }
  }

  /// Rebuilds the ready state, carrying forward whatever the previous one
  /// knew so an automatic failure can't erase the last successful timestamp.
  LiveLocationReady _ready({
    DateTime? lastSentAt,
    bool? autoSharing,
    String? autoError,
  }) {
    final current = state;
    final previous = current is LiveLocationReady ? current : null;
    return LiveLocationReady(
      lastSentAt: lastSentAt ?? previous?.lastSentAt,
      isAutoSharing: autoSharing ?? isAutoSharing,
      // Cleared by any successful send.
      lastError: lastSentAt != null ? null : autoError ?? previous?.lastError,
    );
  }

  @override
  Future<void> close() {
    _autoTimer?.cancel();
    return super.close();
  }
}
