import '../../domain/entities/trip_history_item.dart';

sealed class TripHistoryState {
  const TripHistoryState();
}

class TripHistoryLoading extends TripHistoryState {
  const TripHistoryLoading();
}

class TripHistoryLoaded extends TripHistoryState {
  const TripHistoryLoaded(this.trips);
  final List<TripHistoryItem> trips;
}

class TripHistoryError extends TripHistoryState {
  const TripHistoryError(this.message);
  final String message;
}
