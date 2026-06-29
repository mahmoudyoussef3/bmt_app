import 'package:bmt_app/apps/dashboard/modules/fleet/shared/domain/entities/fleet_assignment.dart';
import 'package:bmt_app/apps/dashboard/modules/fleet/shared/domain/entities/fleet_driver.dart';
import 'package:bmt_app/apps/dashboard/modules/fleet/shared/domain/entities/fleet_vehicle.dart';

sealed class FleetAssignmentsState {
  const FleetAssignmentsState();
}

class FleetAssignmentsLoading extends FleetAssignmentsState {
  const FleetAssignmentsLoading();
}

class FleetAssignmentsError extends FleetAssignmentsState {
  final String message;
  const FleetAssignmentsError(this.message);
}

class FleetAssignmentsLoaded extends FleetAssignmentsState {
  final List<FleetAssignment> assignments;
  final List<FleetDriver> drivers;
  final List<FleetVehicle> vehicles;
  final String searchQuery;
  final String filter;

  const FleetAssignmentsLoaded({
    required this.assignments,
    required this.drivers,
    required this.vehicles,
    this.searchQuery = '',
    this.filter = 'الكل',
  });

  FleetAssignmentsLoaded copyWith({
    List<FleetAssignment>? assignments,
    List<FleetDriver>? drivers,
    List<FleetVehicle>? vehicles,
    String? searchQuery,
    String? filter,
  }) {
    return FleetAssignmentsLoaded(
      assignments: assignments ?? this.assignments,
      drivers: drivers ?? this.drivers,
      vehicles: vehicles ?? this.vehicles,
      searchQuery: searchQuery ?? this.searchQuery,
      filter: filter ?? this.filter,
    );
  }

  String driverName(String driverId) {
    final d = drivers.where((d) => d.id == driverId);
    return d.isNotEmpty ? d.first.fullName : 'غير معروف';
  }

  String vehicleName(String vehicleId) {
    final v = vehicles.where((v) => v.id == vehicleId);
    return v.isNotEmpty
        ? '${v.first.brand} ${v.first.model} (${v.first.plateNumber})'
        : 'غير معروفة';
  }

  List<FleetAssignment> get filteredAssignments {
    var result = assignments;
    if (filter != 'الكل') {
      result = result.where((a) => a.status.label == filter).toList();
    }
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result.where((a) {
        return driverName(a.driverId).toLowerCase().contains(q) ||
            vehicleName(a.vehicleId).toLowerCase().contains(q);
      }).toList();
    }
    return result;
  }
}
