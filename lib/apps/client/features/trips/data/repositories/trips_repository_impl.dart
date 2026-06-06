import '../../domain/entities/trip.dart';
import '../../domain/repositories/trips_repository.dart';
import '../datasources/mock_trips_datasource.dart';

class TripsRepositoryImpl implements TripsRepository {
  const TripsRepositoryImpl(this._datasource);

  final MockTripsDatasource _datasource;

  @override
  Future<List<TripData>> getTrips() async {
    final models = await _datasource.getTrips();
    return models.map((trip) => trip.toEntity()).toList();
  }

  @override
  Future<TripData?> getTripById(String id) async {
    final model = await _datasource.getTripById(id);
    return model?.toEntity();
  }
}
