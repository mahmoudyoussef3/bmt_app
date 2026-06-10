import '../../../shared/domain/entities/fleet_workspace.dart';

abstract class FleetOverviewState {
  const FleetOverviewState();
}

class FleetOverviewInitial extends FleetOverviewState {}

class FleetOverviewLoading extends FleetOverviewState {}

class FleetOverviewLoaded extends FleetOverviewState {
  final FleetWorkspace workspace;

  const FleetOverviewLoaded(this.workspace);
}

class FleetOverviewError extends FleetOverviewState {
  final String message;

  const FleetOverviewError(this.message);
}
