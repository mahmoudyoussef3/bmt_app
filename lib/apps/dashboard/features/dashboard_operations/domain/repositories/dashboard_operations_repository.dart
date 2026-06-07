import '../entities/dashboard_workspace.dart';

abstract class DashboardOperationsRepository {
  Future<DashboardWorkspace> getWorkspace(String workspaceId);
}
