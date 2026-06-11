import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_vehicle.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_vehicles/domain/usecases/fleet_vehicles_usecases.dart';
import 'fleet_vehicles_state.dart';

class FleetVehiclesCubit extends Cubit<FleetVehiclesState> {
  final GetFleetVehiclesUseCase _getVehicles;
  final CreateFleetVehicleUseCase _createVehicle;
  final UpdateFleetVehicleUseCase _updateVehicle;
  final UpdateFleetVehicleStatusUseCase _updateVehicleStatus;
  final UploadVehicleFileUseCase _uploadFile;
  final DeleteVehicleFileUseCase _deleteFile;

  FleetVehiclesCubit({
    required GetFleetVehiclesUseCase getVehicles,
    required CreateFleetVehicleUseCase createVehicle,
    required UpdateFleetVehicleUseCase updateVehicle,
    required UpdateFleetVehicleStatusUseCase updateVehicleStatus,
    required UploadVehicleFileUseCase uploadFile,
    required DeleteVehicleFileUseCase deleteFile,
  })  : _getVehicles = getVehicles,
        _createVehicle = createVehicle,
        _updateVehicle = updateVehicle,
        _updateVehicleStatus = updateVehicleStatus,
        _uploadFile = uploadFile,
        _deleteFile = deleteFile,
        super(const FleetVehiclesLoading());

  Future<void> load() async {
    emit(const FleetVehiclesLoading());
    try {
      final vehicles = await _getVehicles();
      debugPrint('[FleetVehiclesCubit] Loaded ${vehicles.length} vehicles');
      emit(FleetVehiclesLoaded(vehicles: vehicles));
    } catch (error) {
      debugPrint('[FleetVehiclesCubit] Error: $error');
      emit(FleetVehiclesError(error.toString().replaceAll('Exception: ', '')));
    }
  }

  void search(String query) {
    final current = state;
    if (current is! FleetVehiclesLoaded) return;
    emit(current.copyWith(searchQuery: query, selectedIds: {}));
  }

  void filter(String filter) {
    final current = state;
    if (current is! FleetVehiclesLoaded) return;
    emit(current.copyWith(filter: filter, selectedIds: {}));
  }

  void toggleSelection(String id) {
    final current = state;
    if (current is! FleetVehiclesLoaded) return;
    final next = {...current.selectedIds};
    if (!next.add(id)) next.remove(id);
    emit(current.copyWith(selectedIds: next));
  }

  Future<void> saveVehicle(FleetVehicle vehicle) async {
    try {
      if (vehicle.id.isEmpty) {
        debugPrint('[FleetVehiclesCubit] Creating vehicle: ${vehicle.vehicleCode}');
        await _createVehicle(vehicle);
      } else {
        debugPrint('[FleetVehiclesCubit] Updating vehicle: ${vehicle.id}');
        await _updateVehicle(vehicle);
      }
      await _reload();
    } catch (error) {
      debugPrint('[FleetVehiclesCubit] Error saving: $error');
      emit(FleetVehiclesError(error.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> updateVehicleStatus(String vehicleId, FleetVehicleStatus status) async {
    try {
      await _updateVehicleStatus(vehicleId, status);
      await _reload();
    } catch (error) {
      emit(FleetVehiclesError(error.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> bulkSuspendVehicles() async {
    final current = state;
    if (current is! FleetVehiclesLoaded) return;
    for (final id in current.selectedIds) {
      await _updateVehicleStatus(id, FleetVehicleStatus.suspended);
    }
    await _reload();
  }

  Future<String?> uploadVehicleFile(String bucket, String path, List<int> bytes) async {
    try {
      return await _uploadFile(bucket, path, bytes);
    } catch (error) {
      debugPrint('[FleetVehiclesCubit] Upload error: $error');
      return null;
    }
  }

  Future<String?> deleteVehicleFile(String bucket, String path) async {
    try {
      await _deleteFile(bucket, path);
      return null;
    } catch (error) {
      return error.toString().replaceAll('Exception: ', '');
    }
  }

  Future<void> _reload() async {
    final current = state;
    try {
      final vehicles = await _getVehicles();
      if (current is FleetVehiclesLoaded) {
        emit(current.copyWith(vehicles: vehicles, selectedIds: {}));
      } else {
        emit(FleetVehiclesLoaded(vehicles: vehicles));
      }
    } catch (error) {
      emit(FleetVehiclesError(error.toString().replaceAll('Exception: ', '')));
    }
  }
}
