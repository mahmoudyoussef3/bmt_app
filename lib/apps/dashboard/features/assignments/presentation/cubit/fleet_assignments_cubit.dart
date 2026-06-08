import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/fleet_assignment.dart';
import '../../domain/usecases/assign_vehicle_to_driver_usecase.dart';
import '../../domain/usecases/change_fleet_assignment_usecase.dart';
import '../../domain/usecases/get_fleet_assignments_usecase.dart';
import '../../domain/usecases/remove_fleet_assignment_usecase.dart';
import 'fleet_assignments_state.dart';

class FleetAssignmentsCubit extends Cubit<FleetAssignmentsState> {
  final GetFleetAssignmentsUseCase _getAssignments;
  final AssignVehicleToDriverUseCase _assignVehicleToDriver;
  final ChangeFleetAssignmentUseCase _changeAssignment;
  final RemoveFleetAssignmentUseCase _removeAssignment;

  FleetAssignmentsCubit({
    required GetFleetAssignmentsUseCase getAssignments,
    required AssignVehicleToDriverUseCase assignVehicleToDriver,
    required ChangeFleetAssignmentUseCase changeAssignment,
    required RemoveFleetAssignmentUseCase removeAssignment,
  }) : _getAssignments = getAssignments,
       _assignVehicleToDriver = assignVehicleToDriver,
       _changeAssignment = changeAssignment,
       _removeAssignment = removeAssignment,
       super(const FleetAssignmentsLoading());

  Future<void> load() async {
    emit(const FleetAssignmentsLoading());
    try {
      final data = await _getAssignments();
      emit(
        FleetAssignmentsLoaded(
          assignments: data.assignments,
          drivers: data.drivers,
          vehicles: data.vehicles,
          routes: data.routes,
          selectedAssignment: data.assignments.isEmpty
              ? null
              : data.assignments.first,
        ),
      );
    } catch (error) {
      emit(FleetAssignmentsError(error.toString()));
    }
  }

  void selectAssignment(FleetAssignment assignment) {
    final current = state;
    if (current is! FleetAssignmentsLoaded) return;
    emit(current.copyWith(selectedAssignment: assignment));
  }

  Future<void> assignVehicle({
    required String driverId,
    required String vehicleId,
    required String route,
    required String reason,
  }) async {
    final current = state;
    if (current is! FleetAssignmentsLoaded) return;
    emit(current.copyWith(actionInProgress: true));
    try {
      final assignment = await _assignVehicleToDriver(
        driverId: driverId,
        vehicleId: vehicleId,
        route: route,
        reason: reason,
      );
      await _reloadWithSelection(assignment);
    } catch (error) {
      emit(FleetAssignmentsError(error.toString()));
    }
  }

  Future<void> changeAssignment({
    required String assignmentId,
    required String vehicleId,
    required String route,
    required String reason,
  }) async {
    final current = state;
    if (current is! FleetAssignmentsLoaded) return;
    emit(current.copyWith(actionInProgress: true));
    try {
      final assignment = await _changeAssignment(
        assignmentId: assignmentId,
        vehicleId: vehicleId,
        route: route,
        reason: reason,
      );
      await _reloadWithSelection(assignment);
    } catch (error) {
      emit(FleetAssignmentsError(error.toString()));
    }
  }

  Future<void> removeAssignment({
    required String assignmentId,
    required String reason,
  }) async {
    final current = state;
    if (current is! FleetAssignmentsLoaded) return;
    emit(current.copyWith(actionInProgress: true));
    try {
      final assignment = await _removeAssignment(
        assignmentId: assignmentId,
        reason: reason,
      );
      await _reloadWithSelection(assignment);
    } catch (error) {
      emit(FleetAssignmentsError(error.toString()));
    }
  }

  Future<void> _reloadWithSelection(FleetAssignment selected) async {
    final data = await _getAssignments();
    emit(
      FleetAssignmentsLoaded(
        assignments: data.assignments,
        drivers: data.drivers,
        vehicles: data.vehicles,
        routes: data.routes,
        selectedAssignment: data.assignments.firstWhere(
          (assignment) => assignment.id == selected.id,
          orElse: () => selected,
        ),
      ),
    );
  }
}
