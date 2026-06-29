import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/modules/fleet/fleet_assignments/domain/usecases/fleet_assignments_usecases.dart';
import 'fleet_assignments_state.dart';

class FleetAssignmentsCubit extends Cubit<FleetAssignmentsState> {
  final GetFleetAssignmentsUseCase _getAssignments;
  final GetAssignmentDriversUseCase _getDrivers;
  final GetAssignmentVehiclesUseCase _getVehicles;
  final AssignFleetVehicleUseCase _assignVehicle;
  final ReassignFleetVehicleUseCase _reassignVehicle;
  final RemoveFleetAssignmentUseCase _removeAssignment;
  final DeleteFleetAssignmentUseCase _deleteAssignment;

  FleetAssignmentsCubit({
    required GetFleetAssignmentsUseCase getAssignments,
    required GetAssignmentDriversUseCase getDrivers,
    required GetAssignmentVehiclesUseCase getVehicles,
    required AssignFleetVehicleUseCase assignVehicle,
    required ReassignFleetVehicleUseCase reassignVehicle,
    required RemoveFleetAssignmentUseCase removeAssignment,
    required DeleteFleetAssignmentUseCase deleteAssignment,
  }) : _getAssignments = getAssignments,
       _getDrivers = getDrivers,
       _getVehicles = getVehicles,
       _assignVehicle = assignVehicle,
       _reassignVehicle = reassignVehicle,
       _removeAssignment = removeAssignment,
       _deleteAssignment = deleteAssignment,
       super(const FleetAssignmentsLoading());

  Future<void> load() async {
    emit(const FleetAssignmentsLoading());
    try {
      final assignments = await _getAssignments();
      final drivers = await _getDrivers();
      final vehicles = await _getVehicles();
      debugPrint(
        '[FleetAssignmentsCubit] Loaded ${assignments.length} assignments',
      );
      emit(
        FleetAssignmentsLoaded(
          assignments: assignments,
          drivers: drivers,
          vehicles: vehicles,
        ),
      );
    } catch (error) {
      debugPrint('[FleetAssignmentsCubit] Error: $error');
      emit(
        FleetAssignmentsError(error.toString().replaceAll('Exception: ', '')),
      );
    }
  }

  void search(String query) {
    final current = state;
    if (current is! FleetAssignmentsLoaded) return;
    emit(current.copyWith(searchQuery: query));
  }

  void filter(String filter) {
    final current = state;
    if (current is! FleetAssignmentsLoaded) return;
    emit(current.copyWith(filter: filter));
  }

  Future<String?> assign(String driverId, String vehicleId) async {
    try {
      debugPrint(
        '[FleetAssignmentsCubit] Assigning driver=$driverId vehicle=$vehicleId',
      );
      await _assignVehicle(driverId, vehicleId);
      await _reload();
      return null;
    } catch (error) {
      return error.toString().replaceAll('Exception: ', '');
    }
  }

  Future<String?> reassign(String assignmentId, String vehicleId) async {
    try {
      debugPrint(
        '[FleetAssignmentsCubit] Reassigning $assignmentId to vehicle=$vehicleId',
      );
      await _reassignVehicle(assignmentId, vehicleId);
      await _reload();
      return null;
    } catch (error) {
      return error.toString().replaceAll('Exception: ', '');
    }
  }

  Future<void> removeAssignment(String assignmentId) async {
    try {
      debugPrint('[FleetAssignmentsCubit] Removing assignment $assignmentId');
      await _removeAssignment(assignmentId);
      await _reload();
    } catch (error) {
      emit(
        FleetAssignmentsError(error.toString().replaceAll('Exception: ', '')),
      );
    }
  }

  Future<void> deleteAssignment(String assignmentId) async {
    try {
      debugPrint('[FleetAssignmentsCubit] Deleting assignment $assignmentId');
      await _deleteAssignment(assignmentId);
      await _reload();
    } catch (error) {
      emit(
        FleetAssignmentsError(error.toString().replaceAll('Exception: ', '')),
      );
    }
  }

  Future<void> _reload() async {
    final current = state;
    try {
      final assignments = await _getAssignments();
      final drivers = await _getDrivers();
      final vehicles = await _getVehicles();
      if (current is FleetAssignmentsLoaded) {
        emit(
          current.copyWith(
            assignments: assignments,
            drivers: drivers,
            vehicles: vehicles,
          ),
        );
      } else {
        emit(
          FleetAssignmentsLoaded(
            assignments: assignments,
            drivers: drivers,
            vehicles: vehicles,
          ),
        );
      }
    } catch (error) {
      emit(
        FleetAssignmentsError(error.toString().replaceAll('Exception: ', '')),
      );
    }
  }
}
