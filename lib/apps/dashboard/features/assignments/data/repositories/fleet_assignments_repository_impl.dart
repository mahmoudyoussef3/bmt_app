import '../../domain/entities/fleet_assignment.dart';
import '../../domain/repositories/fleet_assignments_repository.dart';
import '../datasources/mock_fleet_assignments_datasource.dart';

class FleetAssignmentsRepositoryImpl implements FleetAssignmentsRepository {
  final FleetAssignmentsDatasource _datasource;

  const FleetAssignmentsRepositoryImpl(this._datasource);

  @override
  Future<FleetAssignmentsData> getAssignmentsData() async {
    try {
      return await _datasource.fetchAssignmentsData();
    } catch (_) {
      throw Exception('تعذر تحميل تعيينات الأسطول');
    }
  }

  @override
  Future<FleetAssignment> assignVehicleToDriver({
    required String driverId,
    required String vehicleId,
    required String route,
    required String reason,
  }) async {
    try {
      return await _datasource.assignVehicleToDriver(
        driverId: driverId,
        vehicleId: vehicleId,
        route: route,
        reason: reason,
      );
    } catch (_) {
      throw Exception('تعذر إنشاء التعيين');
    }
  }

  @override
  Future<FleetAssignment> changeAssignment({
    required String assignmentId,
    required String vehicleId,
    required String route,
    required String reason,
  }) async {
    try {
      return await _datasource.changeAssignment(
        assignmentId: assignmentId,
        vehicleId: vehicleId,
        route: route,
        reason: reason,
      );
    } catch (_) {
      throw Exception('تعذر تغيير التعيين');
    }
  }

  @override
  Future<FleetAssignment> removeAssignment({
    required String assignmentId,
    required String reason,
  }) async {
    try {
      return await _datasource.removeAssignment(
        assignmentId: assignmentId,
        reason: reason,
      );
    } catch (_) {
      throw Exception('تعذر إزالة التعيين');
    }
  }
}
