import '../entities/dashboard_home_data.dart';

abstract class DashboardHomeRepository {
  Future<DashboardHomeData> getHomeData();
}
