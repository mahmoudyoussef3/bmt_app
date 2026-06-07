import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/dashboard_operations/data/datasources/mock_dashboard_operations_datasource.dart';
import 'package:bmt_app/apps/dashboard/features/dashboard_operations/data/models/dashboard_workspace_model.dart';
import 'package:bmt_app/apps/dashboard/features/dashboard_operations/data/repositories/dashboard_operations_repository_impl.dart';
import 'package:bmt_app/apps/dashboard/features/dashboard_operations/domain/usecases/get_dashboard_workspace_usecase.dart';

void main() {
  group('Dashboard operations clean architecture chain', () {
    test('returns bookings workspace through use case', () async {
      final repository = DashboardOperationsRepositoryImpl(
        MockDashboardOperationsDatasource(),
      );
      final useCase = GetDashboardWorkspaceUseCase(repository);

      final workspace = await useCase('bookings');

      expect(workspace.title, 'الحجوزات');
      expect(workspace.metrics, isNotEmpty);
      expect(workspace.tabs.map((tab) => tab.filter), contains('attention'));
      expect(
        workspace.rows.where((row) => row.status == 'attention'),
        isNotEmpty,
      );
    });

    test('maps datasource failures to dashboard failure message', () async {
      final repository = DashboardOperationsRepositoryImpl(
        _FailingDashboardOperationsDatasource(),
      );
      final useCase = GetDashboardWorkspaceUseCase(repository);

      expect(
        () => useCase('bookings'),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('تعذر تحميل بيانات مساحة العمل'),
          ),
        ),
      );
    });
  });
}

class _FailingDashboardOperationsDatasource
    implements DashboardOperationsDatasource {
  @override
  Future<DashboardWorkspaceModel> fetchWorkspace(String workspaceId) {
    throw StateError('network placeholder failure');
  }
}
