import '../../domain/entities/tracking_trip.dart';
import '../../domain/repositories/tracking_repository.dart';
import '../datasources/mock_tracking_datasource.dart';

class TrackingRepositoryImpl implements TrackingRepository {
  const TrackingRepositoryImpl(this._datasource);

  final MockTrackingDatasource _datasource;

  @override
  Future<TrackingTripData> getTrackingTrip() async {
    final data = await _datasource.getTrackingTrip();
    return data.toEntity();
  }
}
