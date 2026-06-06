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
  });

  final TrackingTripData data;
  final TrackingTripState currentState;
  final String title;
  final TrackingRatings ratings;

  TrackingLoaded copyWith({
    TrackingTripState? currentState,
    String? title,
    TrackingRatings? ratings,
  }) {
    return TrackingLoaded(
      data: data,
      currentState: currentState ?? this.currentState,
      title: title ?? this.title,
      ratings: ratings ?? this.ratings,
    );
  }
}

class TrackingError extends TrackingState {
  const TrackingError(this.message);

  final String message;
}
