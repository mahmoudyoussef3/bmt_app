import 'package:flutter_bloc/flutter_bloc.dart';

import '../../shared/domain/entities/fleet_workspace.dart';
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

  // Document & File use cases
  final CreateFleetDocumentUseCase _createDocument;
  final UpdateFleetDocumentUseCase _updateDocument;
  final DeleteFleetDocumentUseCase _deleteDocument;
  final UploadFleetFileUseCase _uploadFile;
  final DeleteFleetFileUseCase _deleteFile;

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
    required CreateFleetDocumentUseCase createDocument,
    required UpdateFleetDocumentUseCase updateDocument,
    required DeleteFleetDocumentUseCase deleteDocument,
    required UploadFleetFileUseCase uploadFile,
    required DeleteFleetFileUseCase deleteFile,
  })  : _getWorkspace = getWorkspace,
        _createDriver = createDriver,
        _updateDriver = updateDriver,
        _updateDriverStatus = updateDriverStatus,
        _createVehicle = createVehicle,
        _updateVehicle = updateVehicle,
        _updateVehicleStatus = updateVehicleStatus,
        _assignVehicle = assignVehicle,
        _reassignVehicle = reassignVehicle,
        _removeAssignment = removeAssignment,
        _createDocument = createDocument,
        _updateDocument = updateDocument,
        _deleteDocument = deleteDocument,
        _uploadFile = uploadFile,
        _deleteFile = deleteFile,
        super(const FleetLoading());

  Future<void> load() async {
    emit(const FleetLoading());
    try {
      emit(FleetLoaded(workspace: await _getWorkspace()));
    } catch (error) {
      emit(FleetError(error.toString().replaceAll('Exception: ', '')));
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
      emit(FleetError(error.toString().replaceAll('Exception: ', '')));
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
      emit(FleetError(error.toString().replaceAll('Exception: ', '')));
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
      emit(FleetError(error.toString().replaceAll('Exception: ', '')));
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
      emit(FleetError(error.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<String?> assign(String driverId, String vehicleId) async {
    try {
      await _assignVehicle(driverId, vehicleId);
      await _reloadKeepingState();
      return null;
    } catch (error) {
      return error.toString().replaceAll('Exception: ', '');
    }
  }

  Future<String?> reassign(String assignmentId, String vehicleId) async {
    try {
      await _reassignVehicle(assignmentId, vehicleId);
      await _reloadKeepingState();
      return null;
    } catch (error) {
      return error.toString().replaceAll('Exception: ', '');
    }
  }

  Future<void> removeAssignment(String assignmentId) async {
    try {
      await _removeAssignment(assignmentId);
      await _reloadKeepingState();
    } catch (error) {
      emit(FleetError(error.toString().replaceAll('Exception: ', '')));
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

  // Document & Storage Workflows
  Future<String?> uploadDocumentFile(
    String bucket,
    String path,
    List<int> bytes,
  ) async {
    try {
      final url = await _uploadFile(bucket, path, bytes);
      return url;
    } catch (error) {
      emit(FleetError(error.toString().replaceAll('Exception: ', '')));
      return null;
    }
  }

  Future<String?> saveDocument({
    required String ownerId,
    required bool isDriver,
    required FleetDocumentType type,
    required String fileUrl,
    required String expiryDate,
    String? documentId,
  }) async {
    try {
      final status = _calculateDocumentStatus(expiryDate);
      if (documentId == null || documentId.isEmpty) {
        await _createDocument(
          ownerId: ownerId,
          isDriver: isDriver,
          type: type,
          fileUrl: fileUrl,
          expiryDate: expiryDate,
          status: status,
        );
      } else {
        await _updateDocument(
          documentId: documentId,
          isDriver: isDriver,
          fileUrl: fileUrl,
          expiryDate: expiryDate,
          status: status,
        );
      }
      await _reloadKeepingState();
      return null;
    } catch (error) {
      return error.toString().replaceAll('Exception: ', '');
    }
  }

  Future<String?> deleteDocument({
    required String documentId,
    required bool isDriver,
  }) async {
    try {
      await _deleteDocument(documentId: documentId, isDriver: isDriver);
      await _reloadKeepingState();
      return null;
    } catch (error) {
      return error.toString().replaceAll('Exception: ', '');
    }
  }

  Future<String?> deleteFile(String bucket, String path) async {
    try {
      await _deleteFile(bucket, path);
      return null;
    } catch (error) {
      return error.toString().replaceAll('Exception: ', '');
    }
  }

  FleetDocumentStatus _calculateDocumentStatus(String expiryDate) {
    try {
      final date = DateTime.tryParse(expiryDate);
      if (date != null) {
        final difference = date.difference(DateTime.now()).inDays;
        if (difference < 0) return FleetDocumentStatus.expired;
        if (difference <= 30) return FleetDocumentStatus.expiringSoon;
        return FleetDocumentStatus.valid;
      }
    } catch (_) {}
    return FleetDocumentStatus.valid;
  }

  Future<void> _reloadKeepingState({bool clearSelection = false}) async {
    final current = state;
    try {
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
    } catch (error) {
      emit(FleetError(error.toString().replaceAll('Exception: ', '')));
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
