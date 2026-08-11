import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/tracking_trip.dart';
import '../../domain/usecases/watch_tracking_trip_usecase.dart';
import '../../domain/usecases/watch_vehicle_position_usecase.dart';

/// The cubit's realtime plumbing: the live position stream and the trip-change
/// stream, plus the bookkeeping that keeps exactly one of each alive.
class TrackingSubscriptions {
  TrackingSubscriptions({
    required WatchVehiclePositionUseCase watchVehiclePosition,
    required WatchTrackingTripUseCase watchTrackingTrip,
    required this.onFix,
    required this.onTripChanged,
  }) : _watchVehiclePosition = watchVehiclePosition,
       _watchTrackingTrip = watchTrackingTrip;

  final WatchVehiclePositionUseCase _watchVehiclePosition;
  final WatchTrackingTripUseCase _watchTrackingTrip;
  final void Function(TrackingPoint fix) onFix;
  final VoidCallback onTripChanged;

  StreamSubscription<TrackingPoint>? _locationSub;
  StreamSubscription<void>? _changesSub;
  Timer? _debounce;
  String? _locationTripId;
  String? _changesTripId;

  /// A finished trip has no more positions to report; holding the channel open
  /// keeps a socket alive for nothing.
  ///
  /// [canTrack] is the rider's own eligibility. Once they board, this rider stops
  /// receiving positions — but the captain keeps publishing and every other rider
  /// still waiting down the route keeps their feed, because the boundary is
  /// `can_read_trip_fixes` evaluated per booking, not a switch on the trip.
  /// Dropping the subscription here is the courteous half; the database is the
  /// half that matters.
  void syncLocation(
    String tripId,
    TrackingTripState state, {
    bool canTrack = true,
  }) {
    if (state.isFinished || !canTrack) return cancelLocation();
    if (_locationTripId == tripId && _locationSub != null) return;

    cancelLocation();
    _locationTripId = tripId;
    _locationSub = _watchVehiclePosition(tripId).listen(
      onFix,
      onError: (Object e) => debugPrint('Tracking location stream error: $e'),
    );
  }

  void syncTripChanges(String tripId) {
    if (_changesTripId == tripId && _changesSub != null) return;

    cancelTripChanges();
    _changesTripId = tripId;
    _changesSub = _watchTrackingTrip(tripId).listen(
      (_) {
        
        _debounce?.cancel();
        _debounce = Timer(const Duration(milliseconds: 250), onTripChanged);
      },
      onError: (Object e) => debugPrint('Tracking trip stream error: $e'),
    );
  }

  void cancelLocation() {
    _locationSub?.cancel();
    _locationSub = null;
    _locationTripId = null;
  }

  void cancelTripChanges() {
    _debounce?.cancel();
    _debounce = null;
    _changesSub?.cancel();
    _changesSub = null;
    _changesTripId = null;
  }

  void cancelAll() {
    cancelLocation();
    cancelTripChanges();
  }
}
