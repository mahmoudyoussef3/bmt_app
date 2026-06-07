import '../../domain/entities/operation_trip.dart';
import '../../domain/repositories/trips_repository.dart';
import '../datasources/mock_trips_datasource.dart';

class TripsRepositoryImpl implements TripsRepository {
  final TripsDatasource _datasource;

  const TripsRepositoryImpl(this._datasource);

  @override
  Future<List<OperationTrip>> getTrips() async {
    try {
      return await _datasource.fetchTrips();
    } catch (_) {
      throw Exception('تعذر تحميل الرحلات');
    }
  }

  @override
  Future<OperationTrip> updateTripStatus(
    String tripId,
    OperationTripStatus status,
  ) async {
    try {
      return await _datasource.updateTripStatus(tripId, status);
    } catch (_) {
      throw Exception('تعذر تحديث حالة الرحلة');
    }
  }
}
