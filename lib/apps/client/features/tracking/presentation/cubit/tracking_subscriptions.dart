import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/usecases/watch_tracking_trip_usecase.dart';

/// The cubit's realtime plumbing: the trip-change stream, and the bookkeeping
/// that keeps exactly one of it alive.
///
/// The vehicle position feed used to live here too. It is now
/// `LiveTrackingBloc`'s, and deliberately only its: with both a cubit and a bloc
/// subscribed, one trip would cost two channels and the same rows would be folded
/// into two progress engines that could disagree about which stops had been
/// passed.
class TrackingSubscriptions {
  TrackingSubscriptions({
    required WatchTrackingTripUseCase watchTrackingTrip,
    required this.onTripChanged,
  }) : _watchTrackingTrip = watchTrackingTrip;

  final WatchTrackingTripUseCase _watchTrackingTrip;
  final VoidCallback onTripChanged;

  StreamSubscription<void>? _changesSub;
  Timer? _debounce;
  String? _changesTripId;

  void syncTripChanges(String tripId) {
    if (_changesTripId == tripId && _changesSub != null) return;

    cancelTripChanges();
    _changesTripId = tripId;
    _changesSub = _watchTrackingTrip(tripId).listen(
      (_) {
        // Six tables feed this signal and a single operational action can touch
        // several at once; refetching per row would be several round trips to
        // arrive at one answer.
        _debounce?.cancel();
        _debounce = Timer(const Duration(milliseconds: 250), onTripChanged);
      },
      onError: (Object e) => debugPrint('Tracking trip stream error: $e'),
    );
  }

  void cancelTripChanges() {
    _debounce?.cancel();
    _debounce = null;
    _changesSub?.cancel();
    _changesSub = null;
    _changesTripId = null;
  }

  void cancelAll() => cancelTripChanges();
}
