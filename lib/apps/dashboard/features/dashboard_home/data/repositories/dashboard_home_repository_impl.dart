import '../../domain/entities/dashboard_home_data.dart';
import '../../domain/repositories/dashboard_home_repository.dart';
import '../datasources/mock_dashboard_home_datasource.dart';

class DashboardHomeRepositoryImpl implements DashboardHomeRepository {
  final DashboardHomeDatasource _datasource;

  const DashboardHomeRepositoryImpl(this._datasource);

  @override
  Future<DashboardHomeData> getHomeData() async {
    try {
      return await _datasource.fetchHomeData();
    } catch (_) {
      throw Exception('تعذر تحميل بيانات الرئيسية');
    }
  }
}
