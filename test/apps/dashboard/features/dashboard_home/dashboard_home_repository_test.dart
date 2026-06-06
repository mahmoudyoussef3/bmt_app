import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/dashboard_home/data/datasources/mock_dashboard_home_datasource.dart';
import 'package:bmt_app/apps/dashboard/features/dashboard_home/data/repositories/dashboard_home_repository_impl.dart';
import 'package:bmt_app/apps/dashboard/features/dashboard_home/domain/usecases/get_dashboard_home_usecase.dart';

void main() {
  group('Dashboard home clean architecture chain', () {
    test('returns four operations metrics and queues', () async {
      final repository = DashboardHomeRepositoryImpl(
        MockDashboardHomeDatasource(),
      );
      final useCase = GetDashboardHomeUseCase(repository);

      final data = await useCase();

      expect(data.metrics, hasLength(4));
      expect(data.metrics.first.label, 'الحجوزات اليوم');
      expect(data.recentBookings, isNotEmpty);
      expect(data.tripsNeedingAction.first.status, 'تدخل مطلوب');
      expect(data.openTickets.first.status, 'عالية');
    });
  });
}
