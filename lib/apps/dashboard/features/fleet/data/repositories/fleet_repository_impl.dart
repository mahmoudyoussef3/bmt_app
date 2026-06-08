import '../../domain/entities/fleet_workspace.dart';
import '../../domain/repositories/fleet_repository.dart';
import '../datasources/mock_fleet_datasource.dart';

class FleetRepositoryImpl implements FleetRepository {
  final FleetDatasource _datasource;

  const FleetRepositoryImpl(this._datasource);

  @override
  Future<FleetAssignment> assignDriverToVehicle(
    String driverId,
    String vehicleId,
  ) async {
    try {
      return await _datasource.assignDriverToVehicle(driverId, vehicleId);
    } catch (_) {
      throw Exception(
        'تعذر إنشاء التعيين. تأكد أن السائق والمركبة غير مرتبطين.',
      );
    }
  }

  @override
  Future<FleetDriver> createDriver(FleetDriver driver) async {
    try {
      return await _datasource.createDriver(driver);
    } catch (_) {
      throw Exception('تعذر إنشاء السائق');
    }
  }

  @override
  Future<FleetVehicle> createVehicle(FleetVehicle vehicle) async {
    try {
      return await _datasource.createVehicle(vehicle);
    } catch (_) {
      throw Exception('تعذر إنشاء المركبة');
    }
  }

  @override
  Future<FleetWorkspace> getWorkspace() async {
    try {
      return await _datasource.fetchWorkspace();
    } catch (_) {
      throw Exception('تعذر تحميل إدارة الأسطول');
    }
  }

  @override
  Future<FleetAssignment> reassignVehicle(
    String assignmentId,
    String newVehicleId,
  ) async {
    try {
      return await _datasource.reassignVehicle(assignmentId, newVehicleId);
    } catch (_) {
      throw Exception(
        'تعذر تغيير المركبة. المركبة المختارة قد تكون معينة بالفعل.',
      );
    }
  }

  @override
  Future<FleetAssignment> removeAssignment(String assignmentId) async {
    try {
      return await _datasource.removeAssignment(assignmentId);
    } catch (_) {
      throw Exception('تعذر فك التعيين');
    }
  }

  @override
  Future<FleetDriver> updateDriver(FleetDriver driver) async {
    try {
      return await _datasource.updateDriver(driver);
    } catch (_) {
      throw Exception('تعذر تعديل السائق');
    }
  }

  @override
  Future<FleetDriver> updateDriverStatus(
    String driverId,
    FleetDriverStatus status,
  ) async {
    try {
      return await _datasource.updateDriverStatus(driverId, status);
    } catch (_) {
      throw Exception('تعذر تحديث حالة السائق');
    }
  }

  @override
  Future<FleetVehicle> updateVehicle(FleetVehicle vehicle) async {
    try {
      return await _datasource.updateVehicle(vehicle);
    } catch (_) {
      throw Exception('تعذر تعديل المركبة');
    }
  }

  @override
  Future<FleetVehicle> updateVehicleStatus(
    String vehicleId,
    FleetVehicleStatus status,
  ) async {
    try {
      return await _datasource.updateVehicleStatus(vehicleId, status);
    } catch (_) {
      throw Exception('تعذر تحديث حالة المركبة');
    }
  }
}
