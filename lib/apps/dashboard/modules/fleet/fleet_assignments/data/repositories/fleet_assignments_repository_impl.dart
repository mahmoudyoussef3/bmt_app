import 'package:bmt_app/apps/dashboard/modules/fleet/shared/domain/entities/fleet_workspace.dart';
import 'package:bmt_app/apps/dashboard/modules/fleet/data/datasources/fleet_datasource.dart';
import '../../domain/repositories/fleet_assignments_repository.dart';

class FleetAssignmentsRepositoryImpl implements FleetAssignmentsRepository {
  final FleetDatasource _datasource;

  const FleetAssignmentsRepositoryImpl(this._datasource);

  @override
  Future<List<FleetAssignment>> getAssignments() async {
    try {
      final workspace = await _datasource.fetchWorkspace();
      return workspace.assignments;
    } catch (e) {
      throw Exception('تعذر تحميل بيانات التعيينات: $e');
    }
  }

  @override
  Future<List<FleetDriver>> getDrivers() async {
    try {
      final workspace = await _datasource.fetchWorkspace();
      return workspace.drivers;
    } catch (e) {
      throw Exception('تعذر تحميل بيانات السائقين: $e');
    }
  }

  @override
  Future<List<FleetVehicle>> getVehicles() async {
    try {
      final workspace = await _datasource.fetchWorkspace();
      return workspace.vehicles;
    } catch (e) {
      throw Exception('تعذر تحميل بيانات المركبات: $e');
    }
  }

  @override
  Future<FleetAssignment> assignDriverToVehicle(
    String driverId,
    String vehicleId,
  ) async {
    try {
      final workspace = await _datasource.fetchWorkspace();

      final driver = workspace.drivers.firstWhere(
        (d) => d.id == driverId,
        orElse: () => throw Exception('السائق غير موجود في النظام.'),
      );

      final vehicle = workspace.vehicles.firstWhere(
        (v) => v.id == vehicleId,
        orElse: () => throw Exception('المركبة غير موجودة في النظام.'),
      );

      if (driver.status != FleetDriverStatus.active) {
        throw Exception('لا يمكن التعيين لسائق غير نشط أو موقوف.');
      }

      if (vehicle.status != FleetVehicleStatus.active) {
        throw Exception('لا يمكن التعيين لمركبة صيانة أو موقوفة.');
      }

      final hasActiveDriverAssign = workspace.assignments.any(
        (a) =>
            a.driverId == driverId && a.status == FleetAssignmentStatus.active,
      );
      if (hasActiveDriverAssign) {
        throw Exception('السائق مرتبط بالفعل بتعيين نشط.');
      }

      final hasActiveVehicleAssign = workspace.assignments.any(
        (a) =>
            a.vehicleId == vehicleId &&
            a.status == FleetAssignmentStatus.active,
      );
      if (hasActiveVehicleAssign) {
        throw Exception('المركبة مرتبطة بالفعل بتعيين نشط لسائق آخر.');
      }

      final hasExpiredDriverDocs = driver.documents.any(
        (doc) => doc.status == FleetDocumentStatus.expired,
      );
      if (hasExpiredDriverDocs) {
        throw Exception(
          'لا يمكن تعيين السائق لوجود وثائق شخصية منتهية الصلاحية.',
        );
      }

      final hasExpiredVehicleDocs = workspace.documents.any(
        (doc) =>
            doc.ownerId == vehicleId &&
            doc.status == FleetDocumentStatus.expired,
      );
      if (hasExpiredVehicleDocs) {
        throw Exception(
          'لا يمكن تعيين المركبة لوجود رخصة أو وثائق منتهية الصلاحية.',
        );
      }

      return await _datasource.assignDriverToVehicle(driverId, vehicleId);
    } on Exception catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    } catch (_) {
      throw Exception(
        'تعذر إنشاء التعيين. تأكد أن السائق والمركبة غير مرتبطين.',
      );
    }
  }

  @override
  Future<FleetAssignment> reassignVehicle(
    String assignmentId,
    String newVehicleId,
  ) async {
    try {
      final workspace = await _datasource.fetchWorkspace();

      final vehicle = workspace.vehicles.firstWhere(
        (v) => v.id == newVehicleId,
        orElse: () => throw Exception('المركبة غير موجودة.'),
      );

      if (vehicle.status != FleetVehicleStatus.active) {
        throw Exception('لا يمكن التعيين لمركبة غير نشطة أو تحت الصيانة.');
      }

      final hasActiveVehicleAssign = workspace.assignments.any(
        (a) =>
            a.vehicleId == newVehicleId &&
            a.status == FleetAssignmentStatus.active &&
            a.id != assignmentId,
      );
      if (hasActiveVehicleAssign) {
        throw Exception('المركبة الجديدة مرتبطة بالفعل بسائق نشط آخر.');
      }

      final hasExpiredVehicleDocs = workspace.documents.any(
        (doc) =>
            doc.ownerId == newVehicleId &&
            doc.status == FleetDocumentStatus.expired,
      );
      if (hasExpiredVehicleDocs) {
        throw Exception(
          'لا يمكن التعيين للمركبة الجديدة لوجود وثائق منتهية الصلاحية.',
        );
      }

      return await _datasource.reassignVehicle(assignmentId, newVehicleId);
    } on Exception catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    } catch (_) {
      throw Exception('تعذر تغيير المركبة.');
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
  Future<void> deleteAssignment(String assignmentId) async {
    try {
      await _datasource.deleteAssignment(assignmentId);
    } catch (_) {
      throw Exception('تعذر حذف التعيين');
    }
  }
}
