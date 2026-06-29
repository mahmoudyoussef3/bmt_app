import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/modules/fleet/shared/domain/entities/fleet_driver.dart';
import 'package:bmt_app/apps/dashboard/modules/fleet/fleet_drivers/domain/usecases/fleet_drivers_usecases.dart';
import 'fleet_drivers_state.dart';

class FleetDriversCubit extends Cubit<FleetDriversState> {
  final GetFleetDriversUseCase _getDrivers;
  final CreateFleetDriverUseCase _createDriver;
  final UpdateFleetDriverUseCase _updateDriver;
  final UpdateFleetDriverStatusUseCase _updateDriverStatus;
  final DeleteFleetDriverUseCase _deleteDriver;
  final UploadDriverFileUseCase _uploadFile;
  final DeleteDriverFileUseCase _deleteFile;

  FleetDriversCubit({
    required GetFleetDriversUseCase getDrivers,
    required CreateFleetDriverUseCase createDriver,
    required UpdateFleetDriverUseCase updateDriver,
    required UpdateFleetDriverStatusUseCase updateDriverStatus,
    required DeleteFleetDriverUseCase deleteDriver,
    required UploadDriverFileUseCase uploadFile,
    required DeleteDriverFileUseCase deleteFile,
  }) : _getDrivers = getDrivers,
       _createDriver = createDriver,
       _updateDriver = updateDriver,
       _updateDriverStatus = updateDriverStatus,
       _deleteDriver = deleteDriver,
       _uploadFile = uploadFile,
       _deleteFile = deleteFile,
       super(const FleetDriversLoading());

  Future<void> load() async {
    emit(const FleetDriversLoading());
    try {
      final drivers = await _getDrivers();
      debugPrint('[FleetDriversCubit] Loaded ${drivers.length} drivers');
      emit(FleetDriversLoaded(drivers: drivers));
    } catch (error) {
      debugPrint('[FleetDriversCubit] Error loading drivers: $error');
      emit(FleetDriversError(error.toString().replaceAll('Exception: ', '')));
    }
  }

  void search(String query) {
    final current = state;
    if (current is! FleetDriversLoaded) return;
    emit(current.copyWith(searchQuery: query, selectedIds: {}));
  }

  void filter(String filter) {
    final current = state;
    if (current is! FleetDriversLoaded) return;
    emit(current.copyWith(filter: filter, selectedIds: {}));
  }

  void toggleSelection(String id) {
    final current = state;
    if (current is! FleetDriversLoaded) return;
    final next = {...current.selectedIds};
    if (!next.add(id)) next.remove(id);
    emit(current.copyWith(selectedIds: next));
  }

  void clearSelection() {
    final current = state;
    if (current is! FleetDriversLoaded) return;
    emit(current.copyWith(selectedIds: {}));
  }

  /// Creates or updates a driver and returns the persisted entity (with its
  /// id) on success, or null on failure (an error state is emitted). The
  /// returned id lets the screen upload any queued documents afterwards.
  Future<FleetDriver?> saveDriver(FleetDriver driver) async {
    try {
      final FleetDriver saved;
      if (driver.id.isEmpty) {
        debugPrint('[FleetDriversCubit] Creating driver: ${driver.fullName}');
        saved = await _createDriver(driver);
      } else {
        debugPrint('[FleetDriversCubit] Updating driver: ${driver.id}');
        saved = await _updateDriver(driver);
      }
      await _reload();
      return saved;
    } catch (error) {
      debugPrint('[FleetDriversCubit] Error saving driver: $error');
      emit(FleetDriversError(error.toString().replaceAll('Exception: ', '')));
      return null;
    }
  }

  Future<void> updateDriverStatus(
    String driverId,
    FleetDriverStatus status,
  ) async {
    try {
      debugPrint(
        '[FleetDriversCubit] Updating status of $driverId to ${status.name}',
      );
      await _updateDriverStatus(driverId, status);
      await _reload();
    } catch (error) {
      emit(FleetDriversError(error.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> bulkArchiveDrivers() async {
    final current = state;
    if (current is! FleetDriversLoaded) return;
    for (final id in current.selectedIds) {
      await _updateDriverStatus(id, FleetDriverStatus.archived);
    }
    await _reload();
  }

  Future<void> deleteDriver(String driverId) async {
    try {
      await _deleteDriver(driverId);
      await _reload();
    } catch (error) {
      emit(FleetDriversError(error.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<String?> uploadDriverFile(
    String bucket,
    String path,
    List<int> bytes,
  ) async {
    try {
      debugPrint(
        '[FleetDriversCubit] Uploading file: bucket=$bucket path=$path',
      );
      return await _uploadFile(bucket, path, bytes);
    } catch (error) {
      debugPrint('[FleetDriversCubit] Upload error: $error');
      return null;
    }
  }

  Future<String?> deleteDriverFile(String bucket, String path) async {
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
      final drivers = await _getDrivers();
      if (current is FleetDriversLoaded) {
        emit(current.copyWith(drivers: drivers, selectedIds: {}));
      } else {
        emit(FleetDriversLoaded(drivers: drivers));
      }
    } catch (error) {
      emit(FleetDriversError(error.toString().replaceAll('Exception: ', '')));
    }
  }
}
