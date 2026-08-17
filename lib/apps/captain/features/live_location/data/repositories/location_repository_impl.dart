import 'package:bmt_app/core/tracking/vehicle_fix.dart';

import '../../domain/entities/location_sharing_state.dart';
import '../../domain/repositories/location_repository.dart';
import '../datasources/location_datasource.dart';

class LocationRepositoryImpl implements LocationRepository {
  const LocationRepositoryImpl(this._dataSource);

  final LocationDatasource _dataSource;

  @override
  Future<LocationUpdateData> sendLocation(String tripId) async {
    return (await _dataSource.sendLocation(tripId)).toEntity();
  }

  @override
  Future<LocationUpdateData> publishFix(String tripId, VehicleFix fix) async {
    return (await _dataSource.publishFix(tripId, fix)).toEntity();
  }

  @override
  Stream<VehicleFix> watchDevicePosition() =>
      _dataSource.watchDevicePosition();
}
