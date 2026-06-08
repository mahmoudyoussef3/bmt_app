import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/fleet_workspace.dart';
import '../../domain/usecases/fleet_usecases.dart';
import 'fleet_state.dart';

class FleetCubit extends Cubit<FleetState> {
  final GetFleetWorkspaceUseCase _getWorkspace;
  final CreateFleetDriverUseCase _createDriver;
  final UpdateFleetDriverUseCase _updateDriver;
  final UpdateFleetDriverStatusUseCase _updateDriverStatus;
  final CreateFleetVehicleUseCase _createVehicle;
  final UpdateFleetVehicleUseCase _updateVehicle;
  final UpdateFleetVehicleStatusUseCase _updateVehicleStatus;
  final AssignFleetVehicleUseCase _assignVehicle;
  final ReassignFleetVehicleUseCase _reassignVehicle;
  final RemoveUnifiedFleetAssignmentUseCase _removeAssignment;

  FleetCubit({
    required GetFleetWorkspaceUseCase getWorkspace,
    required CreateFleetDriverUseCase createDriver,
    required UpdateFleetDriverUseCase updateDriver,
    required UpdateFleetDriverStatusUseCase updateDriverStatus,
    required CreateFleetVehicleUseCase createVehicle,
    required UpdateFleetVehicleUseCase updateVehicle,
    required UpdateFleetVehicleStatusUseCase updateVehicleStatus,
    required AssignFleetVehicleUseCase assignVehicle,
    required ReassignFleetVehicleUseCase reassignVehicle,
    required RemoveUnifiedFleetAssignmentUseCase removeAssignment,
  }) : _getWorkspace = getWorkspace,
       _createDriver = createDriver,
       _updateDriver = updateDriver,
       _updateDriverStatus = updateDriverStatus,
       _createVehicle = createVehicle,
       _updateVehicle = updateVehicle,
       _updateVehicleStatus = updateVehicleStatus,
       _assignVehicle = assignVehicle,
       _reassignVehicle = reassignVehicle,
       _removeAssignment = removeAssignment,
       super(const FleetLoading());

  Future<void> load() async {
    emit(const FleetLoading());
    try {
      emit(FleetLoaded(workspace: await _getWorkspace()));
    } catch (error) {
      emit(FleetError(error.toString()));
    }
  }

  void changeTab(FleetTab tab) {
    final current = state;
    if (current is! FleetLoaded) return;
    emit(
      current.copyWith(
        tab: tab,
        page: 0,
        filter: 'الكل',
        selectedIds: {},
        sortField: _defaultSort(tab),
      ),
    );
  }

  void search(String query) {
    final current = state;
    if (current is! FleetLoaded) return;
    emit(current.copyWith(searchQuery: query, page: 0, selectedIds: {}));
  }

  void filter(String filter) {
    final current = state;
    if (current is! FleetLoaded) return;
    emit(current.copyWith(filter: filter, page: 0, selectedIds: {}));
  }

  void sort(FleetSortField field) {
    final current = state;
    if (current is! FleetLoaded) return;
    emit(
      current.copyWith(
        sortField: field,
        sortAscending: current.sortField == field
            ? !current.sortAscending
            : true,
      ),
    );
  }

  void page(int page) {
    final current = state;
    if (current is! FleetLoaded) return;
    emit(current.copyWith(page: page < 0 ? 0 : page));
  }

  void toggleSelection(String id) {
    final current = state;
    if (current is! FleetLoaded) return;
    final next = {...current.selectedIds};
    if (!next.add(id)) next.remove(id);
    emit(current.copyWith(selectedIds: next));
  }

  void clearSelection() {
    final current = state;
    if (current is! FleetLoaded) return;
    emit(current.copyWith(selectedIds: {}));
  }

  Future<void> saveDriver(FleetDriver driver) async {
    try {
      if (driver.id.isEmpty) {
        await _createDriver(driver);
      } else {
        await _updateDriver(driver);
      }
      await _reloadKeepingState();
    } catch (error) {
      emit(FleetError(error.toString()));
    }
  }

  Future<void> updateDriverStatus(
    String driverId,
    FleetDriverStatus status,
  ) async {
    try {
      await _updateDriverStatus(driverId, status);
      await _reloadKeepingState();
    } catch (error) {
      emit(FleetError(error.toString()));
    }
  }

  Future<void> saveVehicle(FleetVehicle vehicle) async {
    try {
      if (vehicle.id.isEmpty) {
        await _createVehicle(vehicle);
      } else {
        await _updateVehicle(vehicle);
      }
      await _reloadKeepingState();
    } catch (error) {
      emit(FleetError(error.toString()));
    }
  }

  Future<void> updateVehicleStatus(
    String vehicleId,
    FleetVehicleStatus status,
  ) async {
    try {
      await _updateVehicleStatus(vehicleId, status);
      await _reloadKeepingState();
    } catch (error) {
      emit(FleetError(error.toString()));
    }
  }

  Future<String?> assign(String driverId, String vehicleId) async {
    try {
      await _assignVehicle(driverId, vehicleId);
      await _reloadKeepingState();
      return null;
    } catch (error) {
      return error.toString();
    }
  }

  Future<String?> reassign(String assignmentId, String vehicleId) async {
    try {
      await _reassignVehicle(assignmentId, vehicleId);
      await _reloadKeepingState();
      return null;
    } catch (error) {
      return error.toString();
    }
  }

  Future<void> removeAssignment(String assignmentId) async {
    try {
      await _removeAssignment(assignmentId);
      await _reloadKeepingState();
    } catch (error) {
      emit(FleetError(error.toString()));
    }
  }

  Future<void> bulkArchiveDrivers() async {
    final current = state;
    if (current is! FleetLoaded) return;
    for (final id in current.selectedIds) {
      await _updateDriverStatus(id, FleetDriverStatus.archived);
    }
    await _reloadKeepingState(clearSelection: true);
  }

  Future<void> bulkSuspendVehicles() async {
    final current = state;
    if (current is! FleetLoaded) return;
    for (final id in current.selectedIds) {
      await _updateVehicleStatus(id, FleetVehicleStatus.suspended);
    }
    await _reloadKeepingState(clearSelection: true);
  }

  Future<void> _reloadKeepingState({bool clearSelection = false}) async {
    final current = state;
    final workspace = await _getWorkspace();
    if (current is FleetLoaded) {
      emit(
        current.copyWith(
          workspace: workspace,
          selectedIds: clearSelection ? {} : current.selectedIds,
        ),
      );
    } else {
      emit(FleetLoaded(workspace: workspace));
    }
  }

  FleetSortField _defaultSort(FleetTab tab) {
    return switch (tab) {
      FleetTab.drivers => FleetSortField.name,
      FleetTab.vehicles => FleetSortField.modelYear,
      FleetTab.assignments => FleetSortField.assignedAt,
      FleetTab.documents => FleetSortField.licenseExpiry,
    };
  }
}
