import '../../domain/entities/live_trip.dart';
import '../../domain/repositories/live_trips_repository.dart';
import '../datasources/mock_live_trips_datasource.dart';

class LiveTripsRepositoryImpl implements LiveTripsRepository {
  final LiveTripsDatasource _datasource;

  const LiveTripsRepositoryImpl(this._datasource);

  @override
  Future<List<LiveTrip>> getLiveTrips() async {
    try {
      return await _datasource.fetchLiveTrips();
    } catch (_) {
      throw Exception('تعذر تحميل الرحلات المباشرة');
    }
  }
}
