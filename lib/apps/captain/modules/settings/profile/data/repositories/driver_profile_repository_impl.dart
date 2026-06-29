import '../../domain/entities/driver_profile.dart';
import '../../domain/repositories/driver_profile_repository.dart';
import '../datasources/driver_profile_datasource.dart';

class DriverProfileRepositoryImpl implements DriverProfileRepository {
  const DriverProfileRepositoryImpl(this._dataSource);

  final DriverProfileDataSource _dataSource;

  @override
  Future<DriverProfile> getDriverProfile() => _dataSource.getProfile();
}
