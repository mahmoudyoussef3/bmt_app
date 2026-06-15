import 'dart:typed_data';
import '../../shared/domain/entities/fleet_workspace.dart';
import '../../domain/repositories/fleet_repository.dart';
import '../datasources/fleet_datasource.dart';
import '../datasources/supabase_fleet_datasource.dart';

class FleetRepositoryImpl implements FleetRepository {
  final FleetDatasource _datasource;

  const FleetRepositoryImpl(this._datasource);

  @override
  Future<FleetAssignment> assignDriverToVehicle(
    String driverId,
    String vehicleId,
  ) async {
    try {
      // 1. Fetch current workspace to validate rules locally
      final workspace = await _datasource.fetchWorkspace();

      // Find driver
      final driver = workspace.drivers.firstWhere(
        (d) => d.id == driverId,
        orElse: () => throw Exception('السائق غير موجود في النظام.'),
      );

      // Find vehicle
      final vehicle = workspace.vehicles.firstWhere(
        (v) => v.id == vehicleId,
        orElse: () => throw Exception('المركبة غير موجودة في النظام.'),
      );

      // Rule: Prevent suspended driver assignment
      if (driver.status != FleetDriverStatus.active) {
        throw Exception('لا يمكن التعيين لسائق غير نشط أو موقوف.');
      }

      // Rule: Prevent inactive vehicle assignment
      if (vehicle.status != FleetVehicleStatus.active) {
        throw Exception('لا يمكن التعيين لمركبة صيانة أو موقوفة.');
      }

      // Rule: Prevent duplicate active assignment (Driver)
      final hasActiveDriverAssign = workspace.assignments.any(
        (a) =>
            a.driverId == driverId && a.status == FleetAssignmentStatus.active,
      );
      if (hasActiveDriverAssign) {
        throw Exception('السائق مرتبط بالفعل بتعيين نشط.');
      }

      // Rule: Prevent duplicate active assignment (Vehicle)
      final hasActiveVehicleAssign = workspace.assignments.any(
        (a) =>
            a.vehicleId == vehicleId &&
            a.status == FleetAssignmentStatus.active,
      );
      if (hasActiveVehicleAssign) {
        throw Exception('المركبة مرتبطة بالفعل بتعيين نشط لسائق آخر.');
      }

      // Rule: Prevent expired documents assignment (Driver)
      final hasExpiredDriverDocs = driver.documents.any(
        (doc) => doc.status == FleetDocumentStatus.expired,
      );
      if (hasExpiredDriverDocs) {
        throw Exception(
          'لا يمكن تعيين السائق لوجود وثائق شخصية منتهية الصلاحية.',
        );
      }

      // Rule: Prevent expired documents assignment (Vehicle)
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
  Future<FleetDriver> createDriver(FleetDriver driver) async {
    try {
      // Validate unique national ID / employee code / license if local checking is needed
      final workspace = await _datasource.fetchWorkspace();
      final hasDuplicateNationalId = workspace.drivers.any(
        (d) => d.nationalId == driver.nationalId && d.id != driver.id,
      );
      if (hasDuplicateNationalId) {
        throw Exception('الرقم القومي المدخل مسجل بالفعل لسائق آخر.');
      }

      final hasDuplicateLicense = workspace.drivers.any(
        (d) => d.licenseNumber == driver.licenseNumber && d.id != driver.id,
      );
      if (hasDuplicateLicense) {
        throw Exception('رقم الرخصة المدخل مسجل بالفعل لسائق آخر.');
      }

      final hasDuplicateCode = workspace.drivers.any(
        (d) => d.employeeCode == driver.employeeCode && d.id != driver.id,
      );
      if (hasDuplicateCode) {
        throw Exception('كود الموظف المدخل مسجل بالفعل لسائق آخر.');
      }

      return await _datasource.createDriver(driver);
    } on Exception catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    } catch (_) {
      throw Exception('تعذر إنشاء السائق');
    }
  }

  @override
  Future<FleetVehicle> createVehicle(FleetVehicle vehicle) async {
    try {
      // Validate unique plate number / vehicle code
      final workspace = await _datasource.fetchWorkspace();
      final hasDuplicatePlate = workspace.vehicles.any(
        (v) => v.plateNumber == vehicle.plateNumber && v.id != vehicle.id,
      );
      if (hasDuplicatePlate) {
        throw Exception('رقم اللوحة المدخل مسجل بالفعل لمركبة أخرى.');
      }

      final hasDuplicateCode = workspace.vehicles.any(
        (v) => v.vehicleCode == vehicle.vehicleCode && v.id != vehicle.id,
      );
      if (hasDuplicateCode) {
        throw Exception('كود المركبة المدخل مسجل بالفعل لمركبة أخرى.');
      }

      return await _datasource.createVehicle(vehicle);
    } on Exception catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    } catch (_) {
      throw Exception('تعذر إنشاء المركبة');
    }
  }

  @override
  Future<FleetWorkspace> getWorkspace() async {
    try {
      return await _datasource.fetchWorkspace();
    } catch (e) {
      throw Exception('تعذر تحميل إدارة الأسطول: $e');
    }
  }

  @override
  Future<FleetAssignment> reassignVehicle(
    String assignmentId,
    String newVehicleId,
  ) async {
    try {
      final workspace = await _datasource.fetchWorkspace();

      // Find vehicle to reassign
      final vehicle = workspace.vehicles.firstWhere(
        (v) => v.id == newVehicleId,
        orElse: () => throw Exception('المركبة غير موجودة.'),
      );

      // Validate vehicle active status
      if (vehicle.status != FleetVehicleStatus.active) {
        throw Exception('لا يمكن التعيين لمركبة غير نشطة أو تحت الصيانة.');
      }

      // Validate vehicle active assignments
      final hasActiveVehicleAssign = workspace.assignments.any(
        (a) =>
            a.vehicleId == newVehicleId &&
            a.status == FleetAssignmentStatus.active &&
            a.id != assignmentId,
      );
      if (hasActiveVehicleAssign) {
        throw Exception('المركبة الجديدة مرتبطة بالفعل بسائق نشط آخر.');
      }

      // Validate vehicle documents
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
      // Validate unique national ID / employee code / license if changed
      final workspace = await _datasource.fetchWorkspace();
      final hasDuplicateNationalId = workspace.drivers.any(
        (d) => d.nationalId == driver.nationalId && d.id != driver.id,
      );
      if (hasDuplicateNationalId) {
        throw Exception('الرقم القومي المدخل مسجل بالفعل لسائق آخر.');
      }

      final hasDuplicateLicense = workspace.drivers.any(
        (d) => d.licenseNumber == driver.licenseNumber && d.id != driver.id,
      );
      if (hasDuplicateLicense) {
        throw Exception('رقم الرخصة المدخل مسجل بالفعل لسائق آخر.');
      }

      final hasDuplicateCode = workspace.drivers.any(
        (d) => d.employeeCode == driver.employeeCode && d.id != driver.id,
      );
      if (hasDuplicateCode) {
        throw Exception('كود الموظف المدخل مسجل بالفعل لسائق آخر.');
      }

      return await _datasource.updateDriver(driver);
    } on Exception catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
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
      // Validate unique plate number / vehicle code if changed
      final workspace = await _datasource.fetchWorkspace();
      final hasDuplicatePlate = workspace.vehicles.any(
        (v) => v.plateNumber == vehicle.plateNumber && v.id != vehicle.id,
      );
      if (hasDuplicatePlate) {
        throw Exception('رقم اللوحة المدخل مسجل بالفعل لمركبة أخرى.');
      }

      final hasDuplicateCode = workspace.vehicles.any(
        (v) => v.vehicleCode == vehicle.vehicleCode && v.id != vehicle.id,
      );
      if (hasDuplicateCode) {
        throw Exception('كود المركبة المدخل مسجل بالفعل لمركبة أخرى.');
      }

      return await _datasource.updateVehicle(vehicle);
    } on Exception catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
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

  @override
  Future<FleetDocument> createDocument({
    required String ownerId,
    required bool isDriver,
    required FleetDocumentType type,
    required String fileUrl,
    required String expiryDate,
    required FleetDocumentStatus status,
  }) async {
    try {
      return await _datasource.createDocument(
        ownerId: ownerId,
        isDriver: isDriver,
        type: type,
        fileUrl: fileUrl,
        expiryDate: expiryDate,
        status: status,
      );
    } catch (_) {
      throw Exception('تعذر حفظ الوثيقة');
    }
  }

  @override
  Future<FleetDocument> updateDocument({
    required String documentId,
    required bool isDriver,
    required String fileUrl,
    required String expiryDate,
    required FleetDocumentStatus status,
  }) async {
    try {
      return await _datasource.updateDocument(
        documentId: documentId,
        isDriver: isDriver,
        fileUrl: fileUrl,
        expiryDate: expiryDate,
        status: status,
      );
    } catch (_) {
      throw Exception('تعذر تحديث الوثيقة');
    }
  }

  @override
  Future<void> deleteDocument({
    required String documentId,
    required bool isDriver,
  }) async {
    try {
      await _datasource.deleteDocument(
        documentId: documentId,
        isDriver: isDriver,
      );
    } catch (_) {
      throw Exception('تعذر حذف الوثيقة');
    }
  }

  @override
  Future<String> uploadFile(String bucket, String path, List<int> bytes) async {
    try {
      final datasource = _datasource;
      if (datasource is SupabaseFleetDatasource) {
        return await datasource.uploadFile(
          bucket,
          path,
          Uint8List.fromList(bytes),
        );
      }
      throw Exception('رفع الملفات متاح فقط من خلال مصدر Supabase الحقيقي.');
    } catch (_) {
      throw Exception('تعذر رفع الملف لمخزن البيانات');
    }
  }

  @override
  Future<void> deleteFile(String bucket, String path) async {
    try {
      final datasource = _datasource;
      if (datasource is SupabaseFleetDatasource) {
        await datasource.deleteFile(bucket, path);
      }
    } catch (_) {
      throw Exception('تعذر حذف الملف من مخزن البيانات');
    }
  }
}
