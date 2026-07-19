import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/vehicle_detail.dart';
import '../../domain/usecases/get_vehicles_usecase.dart';
import '../../domain/usecases/sort_vehicles_usecase.dart';
import 'vehicle_listing_state.dart';

/// Loads the bookable vehicles for a route and re-sorts them in place without
/// refetching when the rider changes the sort order.
class VehicleListingCubit extends Cubit<VehicleListingState> {
  VehicleListingCubit(this._getVehicles, this._sortVehicles)
    : super(const VehicleListingLoading());

  final GetVehiclesUseCase _getVehicles;
  final SortVehiclesUseCase _sortVehicles;

  List<VehicleDetailData> _raw = const [];
  VehicleSortOption _sort = VehicleSortOption.recommended;
  bool _inFlight = false;

  Future<void> load({
    String? routeId,
    VehicleSortOption sort = VehicleSortOption.recommended,
  }) async {
    if (_inFlight) return;
    _inFlight = true;
    _sort = sort;
    emit(const VehicleListingLoading());
    try {
      _raw = await _getVehicles(routeId: routeId);
      emit(
        VehicleListingLoaded(vehicles: _sortVehicles(_raw, _sort), sort: _sort),
      );
    } catch (error) {
      emit(VehicleListingError(error.toString()));
    } finally {
      _inFlight = false;
    }
  }

  void setSort(VehicleSortOption sort) {
    final current = state;
    if (current is! VehicleListingLoaded || current.sort == sort) return;
    _sort = sort;
    emit(current.copyWith(vehicles: _sortVehicles(_raw, sort), sort: sort));
  }

  void select(String id) {
    final current = state;
    if (current is! VehicleListingLoaded) return;
    emit(current.copyWith(selectedVehicleId: id));
  }
}
