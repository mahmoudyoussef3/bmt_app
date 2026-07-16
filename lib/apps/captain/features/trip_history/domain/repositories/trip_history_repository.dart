import '../entities/trip_history_item.dart';
import '../entities/trip_history_stop.dart';

abstract class TripHistoryRepository {
  Future<List<TripHistoryItem>> getTripHistory();
  Future<List<TripHistoryStop>> getTripStops(String tripId);
}
