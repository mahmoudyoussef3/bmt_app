import '../../domain/repositories/seen_trips_repository.dart';
import '../datasources/seen_trips_local_datasource.dart';

class SeenTripsRepositoryImpl implements SeenTripsRepository {
  const SeenTripsRepositoryImpl(this._dataSource);

  final SeenTripsLocalDataSource _dataSource;

  @override
  Future<Set<String>> getSeenTripIds() => _dataSource.getSeenTripIds();

  @override
  Future<void> markSeen(Set<String> tripIds) => _dataSource.markSeen(tripIds);
}
