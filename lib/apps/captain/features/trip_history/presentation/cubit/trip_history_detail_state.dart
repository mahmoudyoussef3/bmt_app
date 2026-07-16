import '../../domain/entities/trip_history_stop.dart';

sealed class TripHistoryDetailState {
  const TripHistoryDetailState();
}

class TripHistoryDetailLoading extends TripHistoryDetailState {
  const TripHistoryDetailLoading();
}

class TripHistoryDetailLoaded extends TripHistoryDetailState {
  const TripHistoryDetailLoaded(this.stops);
  final List<TripHistoryStop> stops;
}

class TripHistoryDetailError extends TripHistoryDetailState {
  const TripHistoryDetailError(this.message);
  final String message;
}
