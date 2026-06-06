import '../../domain/entities/dashboard_home_data.dart';

class DashboardHomeModel extends DashboardHomeData {
  const DashboardHomeModel({
    required super.metrics,
    required super.recentBookings,
    required super.tripsNeedingAction,
    required super.delayedDrivers,
    required super.openTickets,
  });
}
