import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/vehicle.dart';
import '../../domain/usecases/create_vehicle_usecase.dart';
import '../../domain/usecases/get_vehicles_usecase.dart';
import '../../domain/usecases/renew_vehicle_document_usecase.dart';
import '../../domain/usecases/update_vehicle_status_usecase.dart';
import '../../domain/usecases/update_vehicle_usecase.dart';
import '../models/vehicle_filters.dart';
import 'vehicles_state.dart';

class VehiclesCubit extends Cubit<VehiclesState> {
  final GetVehiclesUseCase _getVehicles;
  final CreateVehicleUseCase _createVehicle;
  final UpdateVehicleUseCase _updateVehicle;
  final UpdateVehicleStatusUseCase _updateVehicleStatus;
  final RenewVehicleDocumentUseCase _renewDocument;

  VehiclesCubit({
    required GetVehiclesUseCase getVehicles,
    required CreateVehicleUseCase createVehicle,
    required UpdateVehicleUseCase updateVehicle,
    required UpdateVehicleStatusUseCase updateVehicleStatus,
    required RenewVehicleDocumentUseCase renewDocument,
  }) : _getVehicles = getVehicles,
       _createVehicle = createVehicle,
       _updateVehicle = updateVehicle,
       _updateVehicleStatus = updateVehicleStatus,
       _renewDocument = renewDocument,
       super(const VehiclesLoading());

  Future<void> load() async {
    emit(const VehiclesLoading());
    try {
      final vehicles = await _getVehicles();
      emit(VehiclesLoaded(vehicles: vehicles, filters: const VehicleFilters()));
    } catch (error) {
      emit(VehiclesError(error.toString()));
    }
  }

  void showGrid() {
    final current = state;
    if (current is! VehiclesLoaded) return;
    emit(current.copyWith(view: VehiclesView.grid, clearSelectedVehicle: true));
  }

  void showDetails(Vehicle vehicle) {
    final current = state;
    if (current is! VehiclesLoaded) return;
    emit(
      current.copyWith(view: VehiclesView.details, selectedVehicle: vehicle),
    );
  }

  void showCreate() {
    final current = state;
    if (current is! VehiclesLoaded) return;
    emit(
      current.copyWith(view: VehiclesView.create, clearSelectedVehicle: true),
    );
  }

  void showEdit(Vehicle vehicle) {
    final current = state;
    if (current is! VehiclesLoaded) return;
    emit(current.copyWith(view: VehiclesView.edit, selectedVehicle: vehicle));
  }

  void updateSearch(String value) {
    final current = state;
    if (current is! VehiclesLoaded) return;
    emit(current.copyWith(filters: current.filters.copyWith(search: value)));
  }

  void updateStatusFilter(VehicleStatus? status) {
    final current = state;
    if (current is! VehiclesLoaded) return;
    emit(
      current.copyWith(
        filters: current.filters.copyWith(
          status: status,
          clearStatus: status == null,
        ),
      ),
    );
  }

  Future<void> saveVehicle(Vehicle vehicle) async {
    final current = state;
    if (current is! VehiclesLoaded) return;
    try {
      final saved = vehicle.id.isEmpty
          ? await _createVehicle(vehicle)
          : await _updateVehicle(vehicle);
      final withoutOld = current.vehicles
          .where((item) => item.id != saved.id)
          .toList();
      emit(
        current.copyWith(
          vehicles: [saved, ...withoutOld],
          view: VehiclesView.details,
          selectedVehicle: saved,
        ),
      );
    } catch (error) {
      emit(VehiclesError(error.toString()));
    }
  }

  Future<void> updateVehicleStatus(
    Vehicle vehicle,
    VehicleStatus status,
  ) async {
    final current = state;
    if (current is! VehiclesLoaded) return;
    try {
      final updated = await _updateVehicleStatus(vehicle.id, status);
      _emitUpdatedVehicle(current, updated);
    } catch (error) {
      emit(VehiclesError(error.toString()));
    }
  }

  Future<void> renewDocument(Vehicle vehicle, String documentTitle) async {
    final current = state;
    if (current is! VehiclesLoaded) return;
    try {
      final updated = await _renewDocument(vehicle.id, documentTitle);
      _emitUpdatedVehicle(current, updated);
    } catch (error) {
      emit(VehiclesError(error.toString()));
    }
  }

  void _emitUpdatedVehicle(VehiclesLoaded current, Vehicle updated) {
    final vehicles = current.vehicles
        .map((item) => item.id == updated.id ? updated : item)
        .toList();
    emit(
      current.copyWith(
        vehicles: vehicles,
        selectedVehicle: current.selectedVehicle?.id == updated.id
            ? updated
            : current.selectedVehicle,
      ),
    );
  }
}
