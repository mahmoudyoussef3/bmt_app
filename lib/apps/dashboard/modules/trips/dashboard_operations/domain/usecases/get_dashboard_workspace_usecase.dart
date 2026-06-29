import '../entities/dashboard_workspace.dart';
import '../repositories/dashboard_operations_repository.dart';

class GetDashboardWorkspaceUseCase {
  final DashboardOperationsRepository _repository;

  const GetDashboardWorkspaceUseCase(this._repository);

  Future<DashboardWorkspace> call(String workspaceId) {
    return _repository.getWorkspace(workspaceId);
  }
}
