import '../../domain/entities/trip_history_item.dart';
import '../../domain/entities/trip_history_stop.dart';
import '../../domain/repositories/trip_history_repository.dart';
import '../datasources/trip_history_datasource.dart';

class TripHistoryRepositoryImpl implements TripHistoryRepository {
  const TripHistoryRepositoryImpl(this._dataSource);

  final TripHistoryDataSource _dataSource;

  @override
  Future<List<TripHistoryItem>> getTripHistory() =>
      _dataSource.getTripHistory();

  @override
  Future<List<TripHistoryStop>> getTripStops(String tripId) =>
      _dataSource.getTripStops(tripId);
}
