import '../../domain/entities/dashboard_workspace.dart';

sealed class DashboardWorkspaceState {
  const DashboardWorkspaceState();
}

class DashboardWorkspaceLoading extends DashboardWorkspaceState {
  const DashboardWorkspaceLoading();
}

class DashboardWorkspaceLoaded extends DashboardWorkspaceState {
  final DashboardWorkspace workspace;

  const DashboardWorkspaceLoaded(this.workspace);
}

class DashboardWorkspaceEmpty extends DashboardWorkspaceState {
  const DashboardWorkspaceEmpty();
}

class DashboardWorkspaceError extends DashboardWorkspaceState {
  final String message;

  const DashboardWorkspaceError(this.message);
}
