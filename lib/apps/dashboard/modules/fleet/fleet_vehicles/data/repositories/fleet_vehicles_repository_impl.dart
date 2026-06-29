import 'dart:typed_data';

import 'package:bmt_app/apps/dashboard/modules/fleet/shared/domain/entities/fleet_workspace.dart';
import 'package:bmt_app/apps/dashboard/modules/fleet/data/datasources/fleet_datasource.dart';
import 'package:bmt_app/apps/dashboard/modules/fleet/data/datasources/supabase_fleet_datasource.dart';
import '../../domain/repositories/fleet_vehicles_repository.dart';

class FleetVehiclesRepositoryImpl implements FleetVehiclesRepository {
  final FleetDatasource _datasource;

  const FleetVehiclesRepositoryImpl(this._datasource);

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
  Future<FleetVehicle> createVehicle(FleetVehicle vehicle) async {
    try {
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
  Future<FleetVehicle> updateVehicle(FleetVehicle vehicle) async {
    try {
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
  Future<void> deleteVehicle(String vehicleId) async {
    try {
      await _datasource.deleteVehicle(vehicleId);
    } on Exception catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    } catch (_) {
      throw Exception('تعذر حذف المركبة');
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
