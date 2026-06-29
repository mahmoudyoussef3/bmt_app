import '../entities/driver_profile.dart';

abstract class DriverProfileRepository {
  Future<DriverProfile> getDriverProfile();
}
