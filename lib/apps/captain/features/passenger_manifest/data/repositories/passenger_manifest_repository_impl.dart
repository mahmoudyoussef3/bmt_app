import '../../domain/entities/passenger.dart';
import '../../domain/repositories/passenger_manifest_repository.dart';
import '../datasources/passenger_manifest_datasource.dart';

class PassengerManifestRepositoryImpl implements PassengerManifestRepository {
  const PassengerManifestRepositoryImpl(this._dataSource);

  final PassengerManifestDataSource _dataSource;

  @override
  Future<List<Passenger>> getTripPassengers(String tripId) async {
    final models = await _dataSource.getTripPassengers(tripId);
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Stream<void> watchPassengerUpdates(String tripId) =>
      _dataSource.watchPassengerUpdates(tripId);
}
