import '../../domain/entities/driver.dart';
import '../../domain/repositories/drivers_repository.dart';
import '../datasources/mock_drivers_datasource.dart';

class DriversRepositoryImpl implements DriversRepository {
  final DriversDatasource _datasource;

  const DriversRepositoryImpl(this._datasource);

  @override
  Future<Driver> createDriver(Driver driver) async {
    try {
      return await _datasource.createDriver(driver);
    } catch (_) {
      throw Exception('تعذر إضافة السائق');
    }
  }

  @override
  Future<void> deleteDriver(String driverId) async {
    try {
      await _datasource.deleteDriver(driverId);
    } catch (_) {
      throw Exception('تعذر حذف السائق');
    }
  }

  @override
  Future<List<Driver>> getDrivers() async {
    try {
      return await _datasource.fetchDrivers();
    } catch (_) {
      throw Exception('تعذر تحميل السائقين');
    }
  }

  @override
  Future<Driver> updateDriver(Driver driver) async {
    try {
      return await _datasource.updateDriver(driver);
    } catch (_) {
      throw Exception('تعذر تعديل السائق');
    }
  }

  @override
  Future<Driver> updateDriverStatus(
    String driverId,
    DriverStatus status,
  ) async {
    try {
      return await _datasource.updateDriverStatus(driverId, status);
    } catch (_) {
      throw Exception('تعذر تحديث حالة السائق');
    }
  }
}
