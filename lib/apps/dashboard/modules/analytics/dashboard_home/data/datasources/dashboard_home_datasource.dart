import '../models/dashboard_home_model.dart';

abstract class DashboardHomeDatasource {
  Future<DashboardHomeModel> fetchHomeData();
}
