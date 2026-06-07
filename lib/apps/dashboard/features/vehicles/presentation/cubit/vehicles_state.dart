import '../../domain/entities/vehicle.dart';
import '../models/vehicle_filters.dart';

enum VehiclesView { grid, details, create, edit }

sealed class VehiclesState {
  const VehiclesState();
}

class VehiclesLoading extends VehiclesState {
  const VehiclesLoading();
}

class VehiclesError extends VehiclesState {
  final String message;

  const VehiclesError(this.message);
}

class VehiclesLoaded extends VehiclesState {
  final List<Vehicle> vehicles;
  final VehicleFilters filters;
  final VehiclesView view;
  final Vehicle? selectedVehicle;

  const VehiclesLoaded({
    required this.vehicles,
    required this.filters,
    this.view = VehiclesView.grid,
    this.selectedVehicle,
  });

  List<Vehicle> get filteredVehicles {
    final search = filters.search.trim().toLowerCase();
    return vehicles.where((vehicle) {
      final statusMatch =
          filters.status == null || vehicle.status == filters.status;
      final searchable = [
        vehicle.plateNumber,
        vehicle.currentDriver,
        vehicle.currentRoute,
        vehicle.type,
        vehicle.model,
        vehicle.status.label,
      ].join(' ').toLowerCase();
      final searchMatch = search.isEmpty || searchable.contains(search);
      return statusMatch && searchMatch;
    }).toList();
  }

  int get activeCount {
    return vehicles
        .where((vehicle) => vehicle.status == VehicleStatus.active)
        .length;
  }

  int get maintenanceCount {
    return vehicles
        .where((vehicle) => vehicle.status == VehicleStatus.maintenance)
        .length;
  }

  int get expiredLicenseCount {
    return vehicles
        .where(
          (vehicle) => vehicle.documents.any((document) => document.expired),
        )
        .length;
  }

  VehiclesLoaded copyWith({
    List<Vehicle>? vehicles,
    VehicleFilters? filters,
    VehiclesView? view,
    Vehicle? selectedVehicle,
    bool clearSelectedVehicle = false,
  }) {
    return VehiclesLoaded(
      vehicles: vehicles ?? this.vehicles,
      filters: filters ?? this.filters,
      view: view ?? this.view,
      selectedVehicle: clearSelectedVehicle
          ? null
          : selectedVehicle ?? this.selectedVehicle,
    );
  }
}
