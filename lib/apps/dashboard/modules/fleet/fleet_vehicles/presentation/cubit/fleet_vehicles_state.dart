import 'package:bmt_app/apps/dashboard/modules/fleet/shared/domain/entities/fleet_vehicle.dart';

sealed class FleetVehiclesState {
  const FleetVehiclesState();
}

class FleetVehiclesLoading extends FleetVehiclesState {
  const FleetVehiclesLoading();
}

class FleetVehiclesError extends FleetVehiclesState {
  final String message;
  const FleetVehiclesError(this.message);
}

class FleetVehiclesLoaded extends FleetVehiclesState {
  final List<FleetVehicle> vehicles;
  final String searchQuery;
  final String filter;
  final Set<String> selectedIds;

  const FleetVehiclesLoaded({
    required this.vehicles,
    this.searchQuery = '',
    this.filter = 'الكل',
    this.selectedIds = const {},
  });

  FleetVehiclesLoaded copyWith({
    List<FleetVehicle>? vehicles,
    String? searchQuery,
    String? filter,
    Set<String>? selectedIds,
  }) {
    return FleetVehiclesLoaded(
      vehicles: vehicles ?? this.vehicles,
      searchQuery: searchQuery ?? this.searchQuery,
      filter: filter ?? this.filter,
      selectedIds: selectedIds ?? this.selectedIds,
    );
  }

  List<FleetVehicle> get filteredVehicles {
    var result = vehicles;
    if (filter != 'الكل') {
      result = result.where((v) => v.status.label == filter).toList();
    }
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result
          .where(
            (v) =>
                v.vehicleCode.toLowerCase().contains(q) ||
                v.plateNumber.toLowerCase().contains(q) ||
                v.brand.toLowerCase().contains(q) ||
                v.model.toLowerCase().contains(q),
          )
          .toList();
    }
    return result;
  }
}
