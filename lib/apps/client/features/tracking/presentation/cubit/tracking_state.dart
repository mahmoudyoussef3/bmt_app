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
    this.isRefreshing = false,
    this.isBoarding = false,
    this.boardingError,
  });

  final TrackingTripData data;

  /// A background refetch is in flight; the screen keeps showing the real data
  /// underneath instead of flashing a spinner over it.
  final bool isRefreshing;

  /// The rider's boarding confirmation is in flight.
  final bool isBoarding;

  /// The server's reason for refusing a boarding confirmation — "the vehicle is
  /// not at your stop yet" is a real answer the rider needs, not a generic
  /// failure. Held until dismissed or superseded.
  final String? boardingError;

  TrackingTripState get tripState => data.tripState;

  TrackingLoaded copyWith({
    TrackingTripData? data,
    bool? isRefreshing,
    bool? isBoarding,
    String? boardingError,
    bool clearBoardingError = false,
  }) {
    return TrackingLoaded(
      data: data ?? this.data,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isBoarding: isBoarding ?? this.isBoarding,
      boardingError: clearBoardingError
          ? null
          : (boardingError ?? this.boardingError),
    );
  }
}

class TrackingError extends TrackingState {
  const TrackingError(this.message);

  final String message;
}
