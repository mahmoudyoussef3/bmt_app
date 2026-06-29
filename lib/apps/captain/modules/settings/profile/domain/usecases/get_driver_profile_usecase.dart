import '../entities/driver_profile.dart';
import '../repositories/driver_profile_repository.dart';

class GetDriverProfileUseCase {
  const GetDriverProfileUseCase(this._repository);

  final DriverProfileRepository _repository;

  Future<DriverProfile> call() => _repository.getDriverProfile();
}
