import '../../domain/entities/tracking_trip.dart';

sealed class TrackingState {
  const TrackingState();
}

class TrackingLoading extends TrackingState {
  const TrackingLoading();
}

class TrackingLoaded extends TrackingState {
  const TrackingLoaded({
    required this.data,
    required this.currentState,
    required this.title,
    this.ratings = const TrackingRatings(),
    this.isRefreshing = false,
  });

  final TrackingTripData data;
  final TrackingTripState currentState;
  final String title;
  final TrackingRatings ratings;
  final bool isRefreshing;

  TrackingLoaded copyWith({
    TrackingTripData? data,
    TrackingTripState? currentState,
    String? title,
    TrackingRatings? ratings,
    bool? isRefreshing,
  }) {
    return TrackingLoaded(
      data: data ?? this.data,
      currentState: currentState ?? this.currentState,
      title: title ?? this.title,
      ratings: ratings ?? this.ratings,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

class TrackingError extends TrackingState {
  const TrackingError(this.message);

  final String message;
}
