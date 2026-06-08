import '../../domain/entities/fleet_assignment.dart';

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
  final List<AssignmentDriverOption> drivers;
  final List<AssignmentVehicleOption> vehicles;
  final List<String> routes;
  final FleetAssignment? selectedAssignment;
  final bool actionInProgress;

  const FleetAssignmentsLoaded({
    required this.assignments,
    required this.drivers,
    required this.vehicles,
    required this.routes,
    this.selectedAssignment,
    this.actionInProgress = false,
  });

  List<FleetAssignment> get activeAssignments {
    return assignments
        .where((item) => item.status == FleetAssignmentStatus.active)
        .toList();
  }

  List<FleetAssignment> get history {
    return assignments
        .where((item) => item.status != FleetAssignmentStatus.active)
        .toList();
  }

  FleetAssignmentsLoaded copyWith({
    List<FleetAssignment>? assignments,
    List<AssignmentDriverOption>? drivers,
    List<AssignmentVehicleOption>? vehicles,
    List<String>? routes,
    FleetAssignment? selectedAssignment,
    bool clearSelectedAssignment = false,
    bool? actionInProgress,
  }) {
    return FleetAssignmentsLoaded(
      assignments: assignments ?? this.assignments,
      drivers: drivers ?? this.drivers,
      vehicles: vehicles ?? this.vehicles,
      routes: routes ?? this.routes,
      selectedAssignment: clearSelectedAssignment
          ? null
          : selectedAssignment ?? this.selectedAssignment,
      actionInProgress: actionInProgress ?? this.actionInProgress,
    );
  }
}
