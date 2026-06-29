import '../../domain/entities/dashboard_home_data.dart';

class DashboardHomeModel extends DashboardHomeData {
  const DashboardHomeModel({
    required super.actionItems,
    required super.todayTrips,
    required super.paymentReviews,
    required super.openComplaints,
    required super.subscriptions,
    required super.alerts,
  });
}
