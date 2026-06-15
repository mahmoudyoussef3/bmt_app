import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/dashboard_home/data/datasources/dashboard_home_datasource.dart';
import 'package:bmt_app/apps/dashboard/features/dashboard_home/data/models/dashboard_home_model.dart';
import 'package:bmt_app/apps/dashboard/features/dashboard_home/data/repositories/dashboard_home_repository_impl.dart';
import 'package:bmt_app/apps/dashboard/features/dashboard_home/domain/entities/dashboard_home_data.dart';
import 'package:bmt_app/apps/dashboard/features/dashboard_home/domain/usecases/get_dashboard_home_usecase.dart';

void main() {
  group('Dashboard home clean architecture chain', () {
    test('returns operations center action queues', () async {
      final repository = DashboardHomeRepositoryImpl(
        _DashboardHomeTestDatasource(),
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
        _DashboardHomeTestDatasource(),
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

class _DashboardHomeTestDatasource implements DashboardHomeDatasource {
  @override
  Future<DashboardHomeModel> fetchHomeData() async {
    return const DashboardHomeModel(
      actionItems: [
        OperationsActionItem(
          title: 'حجز بانتظار مراجعة الدفع',
          count: '١',
          description: 'إيصال محول يحتاج اعتماد قبل تثبيت الكرسي',
          targetModule: '/payment-verification',
          priority: OperationsPriority.urgent,
        ),
      ],
      todayTrips: [
        TodayTripSummary(
          name: 'TR-1001',
          route: 'القاهرة - الإسكندرية',
          driver: 'أحمد علي',
          vehicle: 'كوستر BUS-10 أ ب ج 123',
          departureTime: '٨:٠٠ ص',
          capacity: 28,
          bookedSeats: 12,
          status: 'لم تبدأ',
        ),
      ],
      paymentReviews: [
        PaymentReviewItem(
          customerName: 'سارة محمود',
          tripName: 'القاهرة - الإسكندرية',
          method: 'انستا باي',
          amount: '٣٢٠ ج.م',
          receiptTitle: 'إيصال دفع مرفوع',
          receiptMeta: 'مرجع: IPA-1',
        ),
      ],
      openComplaints: [
        ComplaintTicket(
          customerName: 'منى إبراهيم',
          type: 'تأخير رحلة',
          tripName: 'TR-1001',
          lastUpdate: 'منذ ١٠ دقائق',
          owner: 'مشرف التشغيل',
          status: 'مصعدة',
        ),
      ],
      subscriptions: [
        SubscriptionReviewItem(
          customerName: 'نهى جمال',
          packageName: 'باقة عمل شهرية',
          route: 'القاهرة - الإسكندرية',
          startDate: '١-٦-٢٠٢٦',
          endDate: '٣٠-٦-٢٠٢٦',
          remainingTrips: 5,
          status: 'بانتظار الاعتماد',
        ),
      ],
      alerts: [
        OperationsAlert(
          title: 'رحلة متأخرة',
          details: 'TR-1001 لم تبدأ بعد',
          targetModule: '/live-trips',
          priority: OperationsPriority.urgent,
        ),
      ],
    );
  }
}
