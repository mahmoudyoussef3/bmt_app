import '../../domain/entities/captain_trip_status.dart';
import '../../domain/repositories/trip_status_repository.dart';
import '../datasources/trip_status_datasource.dart';

class TripStatusRepositoryImpl implements TripStatusRepository {
  const TripStatusRepositoryImpl(this._dataSource);

  final TripStatusDataSource _dataSource;

  @override
  Future<CaptainTripStatusUpdate> updateStatus(
    String tripId,
    CaptainTripStatus status,
  ) async {
    return (await _dataSource.updateStatus(tripId, status)).toEntity();
  }
}
