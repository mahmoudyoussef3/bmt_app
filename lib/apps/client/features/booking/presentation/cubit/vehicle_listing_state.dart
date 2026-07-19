import '../../domain/entities/vehicle_detail.dart';

sealed class VehicleListingState {
  const VehicleListingState();
}

class VehicleListingLoading extends VehicleListingState {
  const VehicleListingLoading();
}

class VehicleListingLoaded extends VehicleListingState {
  const VehicleListingLoaded({
    required this.vehicles,
    required this.sort,
    this.selectedVehicleId,
  });

  final List<VehicleDetailData> vehicles;
  final VehicleSortOption sort;
  final String? selectedVehicleId;

  VehicleListingLoaded copyWith({
    List<VehicleDetailData>? vehicles,
    VehicleSortOption? sort,
    String? selectedVehicleId,
  }) {
    return VehicleListingLoaded(
      vehicles: vehicles ?? this.vehicles,
      sort: sort ?? this.sort,
      selectedVehicleId: selectedVehicleId ?? this.selectedVehicleId,
    );
  }
}

class VehicleListingError extends VehicleListingState {
  const VehicleListingError(this.message);

  final String message;
}
