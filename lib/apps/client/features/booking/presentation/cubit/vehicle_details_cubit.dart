import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_vehicle_details_usecase.dart';
import '../../domain/usecases/get_vehicles_usecase.dart';
import 'vehicle_details_state.dart';

/// Loads a single vehicle's details, falling back to the first available
/// vehicle when no id is supplied.
class VehicleDetailsCubit extends Cubit<VehicleDetailsState> {
  VehicleDetailsCubit(this._getVehicleDetails, this._getVehicles)
    : super(const VehicleDetailsLoading());

  final GetVehicleDetailsUseCase _getVehicleDetails;
  final GetVehiclesUseCase _getVehicles;
  bool _inFlight = false;

  Future<void> load(String? id) async {
    if (_inFlight) return;
    _inFlight = true;
    emit(const VehicleDetailsLoading());
    try {
      final vehicle = id == null || id.isEmpty
          ? (await _getVehicles()).firstOrNull
          : await _getVehicleDetails(id);
      emit(VehicleDetailsLoaded(vehicle));
    } catch (error) {
      emit(VehicleDetailsError(error.toString()));
    } finally {
      _inFlight = false;
    }
  }
}
