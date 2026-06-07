import '../../domain/entities/dashboard_workspace.dart';
import '../../domain/repositories/dashboard_operations_repository.dart';
import '../datasources/mock_dashboard_operations_datasource.dart';

class DashboardOperationsRepositoryImpl
    implements DashboardOperationsRepository {
  final DashboardOperationsDatasource _datasource;

  const DashboardOperationsRepositoryImpl(this._datasource);

  @override
  Future<DashboardWorkspace> getWorkspace(String workspaceId) async {
    try {
      return await _datasource.fetchWorkspace(workspaceId);
    } catch (_) {
      throw Exception('تعذر تحميل بيانات مساحة العمل');
    }
  }
}
