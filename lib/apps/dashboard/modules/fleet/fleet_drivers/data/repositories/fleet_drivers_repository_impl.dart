import 'dart:typed_data';

import 'package:bmt_app/apps/dashboard/modules/fleet/shared/domain/entities/fleet_workspace.dart';
import 'package:bmt_app/apps/dashboard/modules/fleet/data/datasources/fleet_datasource.dart';
import 'package:bmt_app/apps/dashboard/modules/fleet/data/datasources/supabase_fleet_datasource.dart';
import '../../domain/repositories/fleet_drivers_repository.dart';

class FleetDriversRepositoryImpl implements FleetDriversRepository {
  final FleetDatasource _datasource;

  const FleetDriversRepositoryImpl(this._datasource);

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
  Future<FleetDriver> createDriver(FleetDriver driver) async {
    try {
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
  Future<FleetDriver> updateDriver(FleetDriver driver) async {
    try {
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
  Future<void> deleteDriver(String driverId) async {
    try {
      await _datasource.deleteDriver(driverId);
    } on Exception catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    } catch (_) {
      throw Exception('تعذر حذف السائق');
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
      throw Exception('رفع الملفات متاح فقط مع Supabase');
    } catch (e) {
      throw Exception('تعذر رفع الملف: $e');
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
      throw Exception('تعذر حذف الملف');
    }
  }
}
