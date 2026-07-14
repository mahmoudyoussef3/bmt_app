import 'package:bmt_app/core/tracking/progress/route_progress_snapshot.dart';

import '../../domain/entities/tracking_trip.dart';

sealed class TrackingState {
  const TrackingState();
}

class TrackingLoading extends TrackingState {
  const TrackingLoading();
}

/// The rider has no confirmed booking to track. A real, explainable state —
/// not an error, and not a trip rendered out of placeholders.
class TrackingEmpty extends TrackingState {
  const TrackingEmpty();
}

class TrackingLoaded extends TrackingState {
  const TrackingLoaded({
    required this.data,
    this.progress,
    this.isRefreshing = false,
  });

  final TrackingTripData data;

  /// Live route progress and ETAs from the shared progress engine.
  final RouteProgressSnapshot? progress;

  /// A background refetch is in flight; the screen keeps showing the real data
  /// underneath instead of flashing a spinner over it.
  final bool isRefreshing;

  TrackingTripState get tripState => data.tripState;

  TrackingLoaded copyWith({
    TrackingTripData? data,
    RouteProgressSnapshot? progress,
    bool? isRefreshing,
  }) {
    return TrackingLoaded(
      data: data ?? this.data,
      progress: progress ?? this.progress,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

class TrackingError extends TrackingState {
  const TrackingError(this.message);

  final String message;
}
