import '../../domain/entities/vehicle.dart';
import '../../domain/repositories/vehicles_repository.dart';
import '../datasources/mock_vehicles_datasource.dart';

class VehiclesRepositoryImpl implements VehiclesRepository {
  final VehiclesDatasource _datasource;

  const VehiclesRepositoryImpl(this._datasource);

  @override
  Future<Vehicle> createVehicle(Vehicle vehicle) async {
    try {
      return await _datasource.createVehicle(vehicle);
    } catch (_) {
      throw Exception('تعذر إضافة المركبة');
    }
  }

  @override
  Future<List<Vehicle>> getVehicles() async {
    try {
      return await _datasource.fetchVehicles();
    } catch (_) {
      throw Exception('تعذر تحميل المركبات');
    }
  }

  @override
  Future<Vehicle> renewDocument(String vehicleId, String documentTitle) async {
    try {
      return await _datasource.renewDocument(vehicleId, documentTitle);
    } catch (_) {
      throw Exception('تعذر تجديد المستند');
    }
  }

  @override
  Future<Vehicle> updateVehicle(Vehicle vehicle) async {
    try {
      return await _datasource.updateVehicle(vehicle);
    } catch (_) {
      throw Exception('تعذر تعديل المركبة');
    }
  }

  @override
  Future<Vehicle> updateVehicleStatus(
    String vehicleId,
    VehicleStatus status,
  ) async {
    try {
      return await _datasource.updateVehicleStatus(vehicleId, status);
    } catch (_) {
      throw Exception('تعذر تحديث حالة المركبة');
    }
  }
}
