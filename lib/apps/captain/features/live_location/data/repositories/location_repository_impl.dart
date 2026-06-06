import '../../domain/entities/location_sharing_state.dart';
import '../../domain/repositories/location_repository.dart';
import '../datasources/location_datasource.dart';

class LocationRepositoryImpl implements LocationRepository {
  const LocationRepositoryImpl(this._dataSource);

  final LocationDataSource _dataSource;

  @override
  Future<LocationSharingStateData> startSharing(String tripId) async {
    return (await _dataSource.startSharing(tripId)).toEntity();
  }

  @override
  Future<LocationSharingStateData> stopSharing(String tripId) async {
    return (await _dataSource.stopSharing(tripId)).toEntity();
  }
}
