import '../entities/driver.dart';

abstract class DriversRepository {
  Future<List<Driver>> getDrivers();
  Future<Driver> createDriver(Driver driver);
  Future<Driver> updateDriver(Driver driver);
  Future<Driver> updateDriverStatus(String driverId, DriverStatus status);
  Future<void> deleteDriver(String driverId);
}
