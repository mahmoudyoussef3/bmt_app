import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/dashboard_home/data/datasources/mock_dashboard_home_datasource.dart';
import 'package:bmt_app/apps/dashboard/features/dashboard_home/data/repositories/dashboard_home_repository_impl.dart';
import 'package:bmt_app/apps/dashboard/features/dashboard_home/domain/usecases/get_dashboard_home_usecase.dart';

void main() {
  group('Dashboard home clean architecture chain', () {
    test('returns operations center action queues', () async {
      final repository = DashboardHomeRepositoryImpl(
        MockDashboardHomeDatasource(),
      );
      final useCase = GetDashboardHomeUseCase(repository);

      final data = await useCase();

      expect(data.actionItems.first.title, 'حجز بانتظار مراجعة الدفع');
      expect(data.todayTrips, isNotEmpty);
      expect(data.todayTrips.every((trip) => trip.driver.isNotEmpty), isTrue);
      expect(data.todayTrips.every((trip) => trip.vehicle.isNotEmpty), isTrue);
      expect(data.todayTrips.every((trip) => trip.capacity > 0), isTrue);
      expect(data.paymentReviews.first.receiptTitle, contains('إيصال'));
      expect(
        data.openComplaints.map((ticket) => ticket.status),
        contains('مصعدة'),
      );
      expect(
        data.subscriptions.map((subscription) => subscription.status),
        contains('بانتظار الاعتماد'),
      );
    });

    test('does not expose impossible trip assignment states', () async {
      final repository = DashboardHomeRepositoryImpl(
        MockDashboardHomeDatasource(),
      );
      final useCase = GetDashboardHomeUseCase(repository);

      final data = await useCase();
      final searchableText = [
        ...data.actionItems.map((item) => '${item.title} ${item.description}'),
        ...data.todayTrips.map((trip) => '${trip.name} ${trip.status}'),
        ...data.alerts.map((alert) => '${alert.title} ${alert.details}'),
      ].join(' ');

      expect(searchableText, isNot(contains('إسناد مركبة')));
      expect(searchableText, isNot(contains('إسناد سائق')));
      expect(searchableText, isNot(contains('تحتاج إسناد')));
    });
  });
}
